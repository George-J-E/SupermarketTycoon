//
//  GameView.swift
//  Supermarket Tycoon
//
//  Created by George Elsham on 09/12/2020.
//

import SpriteKit
import SwiftUI


// MARK: - S: GameView
/// Main game screen.
struct GameView: View {
    
    static var scene: GameScene!
    @EnvironmentObject private var outsideData: OutsideData
    @State private var categorySelection: Category = .upgrades
    @State private var setup = false
    private let mode: GameMode
    
    var preferredCategorySelection: Category {
        if outsideData.customerSelection == nil {
            return categorySelection
        } else {
            return .customer
        }
    }
    
    init(mode: GameMode) {
        self.mode = mode
    }
    
    var body: some View {
        if setup {
            NavigationView {
                VStack {
                    VStack(alignment: .leading) {
                        Text("Supermarket Tycoon")
                            .bigTitle()
                            .padding(.vertical)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            ForEach(Category.allCases) { upgradeType in
                                Text(upgradeType.rawValue)
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                                    .underline(if: preferredCategorySelection == upgradeType)
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .cornerRadius(5)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        categorySelection = upgradeType
                                    }
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    
                    VStack(alignment: .leading) {
                        Text(preferredCategorySelection.rawValue)
                            .bigTitle()
                            .padding(.top)
                        
                        switch preferredCategorySelection {
                        case .upgrades:     UpgradesView()
                        case .customer:     CustomerView()
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding()
                .background(Color("Grass"))
                
                GeometryReader { geo in
                    ZStack {
                        // Game scene
                        SpriteView(scene: GameView.scene)
                        
                        // Green bars top and bottom
                        VStack {
                            Color("Grass")
                                .frame(height: geo.size.height / 2 - geo.size.width / 3.2 + 1)
                            
                            Spacer()
                            
                            Color("Grass")
                                .frame(height: barHeight(for: geo.size))
                                .padding(.trailing, Global.debugMode ? 200 : 0)
                        }
                    }
                }
            }
        } else {
            Spacer()
                .onAppear(perform: setupScene)
        }
    }
    
    private func barHeight(for size: CGSize) -> CGFloat {
        size.height / 2 - size.width / 3.2 + 1
    }
    
    private func setupScene() {
        // Remake scene
        let gameScene = GameScene(size: CGSize(width: 1440, height: 900), mode: mode, outsideData: outsideData)
        gameScene.scaleMode = .aspectFit
        GameView.scene = gameScene
        setup = true
    }
}



// MARK: - C: OutsideData
class OutsideData: ObservableObject {
    @Published var hasEnded = false
    @Published var customerSelection: Customer? {
        didSet {
            customerSelection?.showOutline()
            oldValue?.hideOutline()
        }
    }
    @Published var money: Int = 0
    @Published var advertising: Int = 0
    @Published var checkouts: Int = 1
    @Published var speedBoost: Bool = false
}



// MARK: - E: Category
/// Different types of upgrades available.
enum Category: String, CaseIterable, Identifiable {
    case upgrades = "Upgrades"
    case customer = "Customer"
    
    var id: String { rawValue }
}



// MARK: - S: UpgradesView
struct UpgradesView: View {
    
    @EnvironmentObject private var outsideData: OutsideData
    
    init() {}
    
    var body: some View {
        BackgroundBox {
            VStack(alignment: .leading, spacing: 10) {
                UpgradeItem(
                    "Advertising",
                    cost: 10 + outsideData.advertising / 2,
                    value: "\(outsideData.advertising)%",
                    reachedLimit: outsideData.advertising == 500
                ) {
                    try? GameView.scene.gameInfo.removeMoney(amount: 10 + outsideData.advertising / 2)
                    outsideData.advertising += 10
                }
                
                UpgradeItem(
                    "Checkouts",
                    cost: GameView.scene.gameInfo.priceOfNextCheckout(),
                    value: String(outsideData.checkouts),
                    reachedLimit: outsideData.checkouts == 6
                ) {
                    try? GameView.scene.gameInfo.unlockNextCheckout()
                }
                
                UpgradeItem(
                    "Speed boost",
                    cost: 30,
                    value: outsideData.speedBoost ? "Yes" : "No",
                    reachedLimit: outsideData.speedBoost
                ) {
                    try? GameView.scene.gameInfo.removeMoney(amount: 30)
                    outsideData.speedBoost = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        outsideData.speedBoost = false
                    }
                }
            }
            .foregroundColor(.black)
        }
    }
}



// MARK: - S: CustomerView
/// Display information about customers.
struct CustomerView: View {
    
    @EnvironmentObject private var outsideData: OutsideData
    
    init() {}
    
    var body: some View {
        if let customer = outsideData.customerSelection {
            BackgroundBox {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Name:")
                        Text(customer.name)
                    }
                    .foregroundColor(.black)
                    
                    HStack {
                        Text("Age:")
                        Text(String(customer.age))
                    }
                    .foregroundColor(.black)
                    
                    Spacer()
                        .frame(height: 30)
                    
                    Text("Shopping list:")
                        .foregroundColor(.black)
                    
                    BackgroundBox {
                        VStack {
                            ForEach(customer.shoppingList, id: \.item) { shoppingItem in
                                HStack {
                                    Text(shoppingItem.item.name.plural)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    Text(String("x\(shoppingItem.quantityRequired)"))
                                        .foregroundColor(shoppingItem.color)
                                }
                                .frame(width: 200)
                            }
                        }
                    }
                }
            }
        } else {
            BackgroundBox {
                Text("No customer selected")
                    .foregroundColor(Color(white: 0.5))
            }
        }
    }
}



// MARK: - S: UpgradeItem
struct UpgradeItem: View {
    
    @EnvironmentObject private var outsideData: OutsideData
    
    private let title: String
    private let cost: Int
    private let value: String
    private let reachedLimit: Bool
    private let action: () -> Void
    
    private var costColor: Color {
        outsideData.money >= cost ? .green : .red
    }
    
    init(_ title: String, cost: Int, value: String, reachedLimit: Bool, action: @escaping () -> Void) {
        self.title = title
        self.cost = cost
        self.value = value
        self.reachedLimit = reachedLimit
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text("\(title):")
            
            if reachedLimit {
                Text("MAX").foregroundColor(.green)
            } else {
                Text("£\(cost)").foregroundColor(costColor)
            }
            
            Spacer()
            Text(value)
            
            AddNew(isEnabled: outsideData.money >= cost && !reachedLimit, action: action)
        }
    }
}



// MARK: - S: AddNew
/// Button for adding more of something.
struct AddNew: View {
    private let isEnabled: Bool
    private let action: () -> Void
    
    init(isEnabled: Bool, action: @escaping () -> Void) {
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Image(systemName: "plus")
            .frame(width: 30, height: 30)
            .background(Color(white: isEnabled ? 0.9 : 0.7))
            .cornerRadius(5)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.black, lineWidth: 1)
            )
            .onTapGesture(perform: isEnabled ? action : {})
    }
}
