import SwiftUI
import Firebase
import FirebaseFirestore

struct OrderDetailView: View {
    var orderDetail: String
    var totalPrice: Int
    var customerName: String = "測試用"
    var customerPhone: String = "未提供"

    @State private var showAlert = false
    @State private var orderStatus = "訂單已送出"
    @State private var waitTime = "大約 15 分鐘"
    @State private var formSubmitMessage = "尚未提交表單"
    
    // 更改初始化方法為 internal (預設) 或 public
    init(orderDetail: String, totalPrice: Int, customerName: String = "測試用", customerPhone: String = "未提供") {
        self.orderDetail = orderDetail
        self.totalPrice = totalPrice
        self.customerName = customerName
        self.customerPhone = customerPhone
    }
    
    private var db = Firestore.firestore()

    var discountedPrice: Int {
        return totalPrice > 100 ? Int(Double(totalPrice) * 0.9) : totalPrice
    }

    var discountMessage: String {
        return totalPrice > 100 ? "您享有 10% 的折扣！" : ""
    }

    var body: some View {
        VStack {
            ScrollView {
                Text(orderDetail)
                    .font(.body)
                    .padding()
            }

            Spacer()

            Text("總金額: \(totalPrice) 元")
                .font(.title)
                .padding()
            
            if totalPrice > 100 {
                Text("折後金額: \(discountedPrice) 元")
                    .font(.title)
                    .foregroundColor(.green)
                    .padding(.bottom)
                Text(discountMessage)
                    .font(.title)
                    .foregroundColor(.blue)
                    .padding(.bottom)
            }

            Button(action: {
                handleSubmitOrder() // 合併動作
            }) {
                Text("提交並完成訂單")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("表單提交訊息"),
                message: Text(formSubmitMessage),
                dismissButton: .default(Text("確定"))
            )
        }
        .navigationTitle("訂單明細")
    }

    // MARK: - 提交並完成訂單
    private func handleSubmitOrder() {
        submitGoogleForm() // 提交 Google 表單
        saveOrderToFirestore() // 儲存訂單至 Firestore
        fetchOrderStatus() // 更新訂單狀態
        showAlert = true  // 顯示提醒視窗
    }

    // MARK: - 儲存訂單資料到 Firestore
    private func saveOrderToFirestore() {
        let out3 = removeNonChineseCharacters(from: orderDetail)
        let out4 = cleanOrderDetails(from: orderDetail)

        let orderRef = db.collection("orders").addDocument(data: [
            "orderDetail": out3,
            "orderDigital": out4,
            "totalPrice": totalPrice,
            "customerName": customerName,
            "customerPhone": customerPhone,
            "timestamp": Timestamp() // 取得當前時間
        ]) { error in
            if let error = error {
                print("儲存訂單失敗: \(error.localizedDescription)")
                formSubmitMessage = "儲存訂單失敗：\(error.localizedDescription)"
            } else {
                print("訂單儲存成功")
                formSubmitMessage = "訂單儲存成功！"
            }
        }
    }

    // MARK: - 提交 Google Form
    private func submitGoogleForm() {
        guard let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeDBJj6oPLPKAGyh9h4wlxx2sKH9KlqP6Y_2LYgjx5ljORYog/formResponse") else {
            print("無效的表單 URL")
            formSubmitMessage = "無效的表單 URL"
            return
        }
        print("order = \(orderDetail)")
        let out3 = removeNonChineseCharacters(from: orderDetail)
        let out4 = cleanOrderDetails(from: orderDetail)
        print("out3 = \(out3)")
        print("out4 = \(out4)")

        let parameters: [String: String] = [
            "entry.1764548066": customerName, // 顧客名稱
            "entry.493604499": out3,  // 訂單內容
            "entry.199042070": out4, // 訂單數量
            "entry.1052988240": "\(discountedPrice)", // 折後金額
            "entry.1346496874": customerPhone  // 電話
        ]

        // 為每個參數進行百分比編碼
        let encodedParameters = parameters.map { key, value in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")

        guard let postData = encodedParameters.data(using: .utf8) else {
            formSubmitMessage = "參數編碼失敗"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("提交失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    formSubmitMessage = "提交失敗：\(error.localizedDescription)"
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("提交成功")
                DispatchQueue.main.async {
                    formSubmitMessage = "表單提交成功！"
                }
            } else {
                print("提交失敗，伺服器回應錯誤")
                DispatchQueue.main.async {
                    formSubmitMessage = "提交失敗，伺服器回應錯誤"
                }
            }
        }.resume()
    }

    // MARK: - 模擬訂單狀態檢索
    private func fetchOrderStatus() {
        orderStatus = "訂單已完成"
        waitTime = "感謝您的耐心等候"
    }
    
    private func removeNonChineseCharacters(from text: String) -> String {
        // 首先，去除所有非中文字符
        let regexPattern = "[^\\u4e00-\\u9fa5]" // 只保留中文字符
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)

        var cleanedText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        
        // 接著，將 "元" 替換成換行符號
        cleanedText = cleanedText.replacingOccurrences(of: "元", with: "\n")

        return cleanedText
    }
    
    private func cleanOrderDetails(from text: String) -> String {
        // 步驟 1: 刪除 "-" 和 "|"
        var cleanedText = text.replacingOccurrences(of: "-", with: "")
                                .replacingOccurrences(of: "|", with: "")
        
        // 步驟 2: 刪除所有中文字符
        let regexPattern = "[\\u4e00-\\u9fa5]" // 只匹配中文字符
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        let range = NSRange(location: 0, length: cleanedText.utf16.count)
        
        // 使用正則表達式刪除所有中文字符
        cleanedText = regex.stringByReplacingMatches(in: cleanedText, options: [], range: range, withTemplate: "")
        
        // 步驟 3: 刪除所有空白字符
        cleanedText = cleanedText.replacingOccurrences(of: " ", with: "")
        
        // 步驟 4: 刪除 "=" 後的數字直到換行符
        let removePattern = "=\\s?\\d+\\s*\\n" // 匹配 "=" 後的數字直到換行符
        let removeRegex = try! NSRegularExpression(pattern: removePattern, options: [])
        cleanedText = removeRegex.stringByReplacingMatches(in: cleanedText, options: [], range: NSRange(location: 0, length: cleanedText.utf16.count), withTemplate: "")
        // 步驟 5: 將 "x" 替換為換行符
        cleanedText = cleanedText.replacingOccurrences(of: "x", with: "\n")
        
        
        cleanedText = cleanedText.trimmingCharacters(in: .newlines)

        return cleanedText
    }
}

struct OrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OrderDetailView(
            orderDetail: "範例訂單明細",
            totalPrice: 120,
            customerName: "test",
            customerPhone: "0912345678"
        )
    }
}
