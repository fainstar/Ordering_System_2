//
//  Product.swift
//  Ordering_System
//
//  Created by 蔡尚儒 on 2024/10/23.
//

// Product.swift
import Foundation
import FirebaseFirestore

struct Product: Identifiable {
    let id = UUID() // 唯一標識符
    let name: String // 產品名稱
    let image: String // 圖片名稱
    var quantity: Int // 數量
    let price: Int // 價格
}

struct Order: Identifiable, Codable {
    @DocumentID var id: String?  // Firestore 文件 ID
    var orderDetail: String
    var orderDigital: String
    var totalPrice: Int
    var customerName: String
    var customerPhone: String
    var timestamp: Timestamp
}
