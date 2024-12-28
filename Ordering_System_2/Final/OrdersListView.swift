import SwiftUI
import FirebaseFirestore

struct OrdersListView: View {
    @State private var orders: [Order] = []  // 儲存從 Firestore 讀取的訂單資料
    @State private var isLoading = true  // 載入中狀態
    @State private var showTodayOrders = false  // 判斷是否顯示「今日點餐」

    private var db = Firestore.firestore()  // Firestore 實例

    var body: some View {
        NavigationView {
            VStack {
                // 顯示兩個按鈕來切換顯示狀態
                HStack(spacing: 20) {
                    Button(action: {
                        showTodayOrders = true  // 顯示「今日點餐」
                    }) {
                        Text("今日點餐")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(showTodayOrders ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showTodayOrders = false  // 顯示「所有點餐」
                    }) {
                        Text("所有點餐")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(!showTodayOrders ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
                .padding()

                // 清單筆數顯示
                Text("清單筆數：\(filteredOrders().count) 筆")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom, 10)

                if isLoading {
                    ProgressView()  // 顯示載入中指示器
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    List(filteredOrders()) { order in
                        VStack(alignment: .leading) {
                            // 顯示訂單時間
                            Text("\(order.timestamp.dateValue(), formatter: orderDateFormatter)")
                                .padding()

                            // 顯示訂單內容
                            renderOrderDetails(order: order)

                            // 顯示其他訂單資訊
                            Text("總金額: \(order.totalPrice) 元")
                                .font(.subheadline)
                                .padding(.horizontal)
                            if order.totalPrice > 100 {
                                Text("優惠價: \(Double(order.totalPrice) * 0.9, specifier: "%.2f") 元")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                            } else {
                                Text("優惠價: 未滿100, 沒有優惠!")
                                    .font(.subheadline)
                                    .padding(.horizontal)
                            }
                            Text("顧客: \(order.customerName)")
                                .font(.subheadline)
                                .padding(.horizontal)
                            Text("電話: \(order.customerPhone)")
                                .font(.subheadline)
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                fetchOrders()  // 當視圖顯示時獲取資料
            }
            .navigationTitle("店家端")
        }
    }

    // 從 Firestore 讀取訂單資料
    private func fetchOrders() {
        db.collection("orders")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching orders: \(error.localizedDescription)")
                    isLoading = false
                    return
                }

                // 將 Firestore 資料轉換為 `Order` 模型
                orders = snapshot?.documents.compactMap { document in
                    try? document.data(as: Order.self)
                } ?? []

                isLoading = false
            }
    }

    // 根據是否顯示今日點餐來過濾訂單
    private func filteredOrders() -> [Order] {
        if showTodayOrders {
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: Date())
            let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? Date()

            return orders.filter { order in
                let timestamp = order.timestamp.dateValue()
                return timestamp >= todayStart && timestamp < todayEnd
            }
        } else {
            return orders
        }
    }

    // 顯示訂單內容的品名和數量
    private func renderOrderDetails(order: Order) -> some View {
        let orderDetailsArray = order.orderDetail.split(separator: " ")
        let orderQuantitiesArray = order.orderDigital.split(separator: " ")

        return ForEach(0..<min(orderDetailsArray.count, orderQuantitiesArray.count), id: \.self) { index in
            HStack(alignment: .firstTextBaseline) {
                Text(orderDetailsArray[index])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Text(orderQuantitiesArray[index])
                    .frame(width: 50, alignment: .leading)
                    .padding(.horizontal)
            }
            .padding(.vertical, 2)
        }
    }

    // 日期格式化器
    private var orderDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

