//
//  SystemNotification.swift
//  SystemNotification
//
//  Created by Daniel Saidi on 2021-06-01.
//  Copyright © 2021-2024 Daniel Saidi. All rights reserved.
//

import SwiftUI

/// This view mimics the native iOS system notification that
/// for instance is shown when toggling silent mode.
/// 
/// This view renders a notification shape that contains the
/// provided content view. You can use a custom view, or use
/// a ``SystemNotificationMessage`` for convenience.
///
/// You can use a ``SwiftUI/View/systemNotificationStyle(_:)``
/// and a ``SwiftUI/View/systemNotificationConfiguration(_:)``
/// to style and configure a system notification.
public struct SystemNotification<Content: View>: View {
    
    /// Create a system notification view.
    ///
    /// - Parameters:
    ///   - isActive: A binding that controls the active state of the notification.
    ///   - content: The view to present within the notification badge.
    public init(
        isActive: Binding<Bool>,
        @ViewBuilder content: @escaping ContentBuilder
    ) {
        _isActive = isActive
        self.initStyle = nil
        self.initConfig = nil
        self.content = content
    }
    
    public typealias ContentBuilder = (_ isActive: Bool) -> Content

    private let initConfig: SystemNotificationConfiguration?
    private let initStyle: SystemNotificationStyle?
    private let content: ContentBuilder
    
    @Binding
    private var isActive: Bool
    
    @Environment(\.colorScheme)
    private var colorScheme
    
    @Environment(\.systemNotificationConfiguration)
    private var envConfig
    
    @Environment(\.systemNotificationStyle)
    private var envStyle
    
    @State
    private var currentId = UUID()
    
    public var body: some View {
        ZStack(alignment: edge.alignment) {
            Color.clear
            content(isActive)
                .background(style.backgroundColor)
                .background(style.backgroundMaterial)
                .cornerRadius(style.cornerRadius ?? 1_000)
                .shadow(
                    color: style.shadowColor,
                    radius: style.shadowRadius,
                    y: style.shadowOffset)
                .animation(config.animation, value: isActive)
                .offset(x: 0, y: verticalOffset)
                #if os(iOS) || os(macOS) || os(watchOS) || os(visionOS)
                .gesture(swipeGesture, if: config.isSwipeToDismissEnabled)
                #endif
                .padding(style.padding)
                .onChange(of: isActive, perform: handlePresentation)
        }
    }
}

private extension SystemNotification {
    
    var config: SystemNotificationConfiguration {
        initConfig ?? envConfig
    }

    var edge: SystemNotificationEdge {
        config.edge
    }
    
    var verticalOffset: CGFloat {
        if isActive { return 0 }
        switch edge {
        case .top: return -250
        case .bottom: return 250
        }
    }
    
    func dismiss() {
        isActive = false
    }
    
    var style: SystemNotificationStyle {
        initStyle ?? envStyle
    }
    
    func handlePresentation(_ isPresented: Bool) {
        guard isPresented else { return }
        currentId = UUID()
        let id = currentId
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
            if id == currentId {
                isActive = false
            }
        }
    }
}


// MARK: - Private View Logic

private extension View {

    @ViewBuilder
    func gesture<GestureType: Gesture>(
        _ gesture: GestureType,
        if condition: Bool
    ) -> some View {
        if condition {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

private extension SystemNotification {
    
    @ViewBuilder
    var background: some View {
        if let color = style.backgroundColor {
            color
        } else {
            SystemNotificationStyle.standardBackgroundColor(for: colorScheme)
        }
    }
    
    #if os(iOS) || os(macOS) || os(watchOS) || os(visionOS)
    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .onEnded { value in
                let horizontalTranslation = value.translation.width as CGFloat
                let verticalTranslation = value.translation.height as CGFloat
                let isVertical = abs(verticalTranslation) > abs(horizontalTranslation)
                let isUp = verticalTranslation < 0
                // let isLeft = horizontalTranslation < 0
                guard isVertical else { return }            // We only use vertical edges
                if isUp && edge == .top { dismiss() }
                if !isUp && edge == .bottom { dismiss() }
            }
    }
    #endif
}

#Preview {
    
    struct Preview: View {
        
        @State var isPresented = false
        
        var body: some View {
            ZStack {
                AsyncImage(url: .init(string: "https://picsum.photos/500/500")) {
                    $0.image?
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .clipped()
                .ignoresSafeArea()
                
                SystemNotification(
                    isActive: $isPresented
                ) { param in
                    SystemNotificationMessage(
                        icon: Image(systemName: "bell.fill"),
                        title: "Silent mode",
                        text: "Silent mode is off"
                    )
                }
                .systemNotificationStyle(.standard)
                .systemNotificationConfiguration(
                    .init(animation: .bouncy)
                )
                
                SystemNotification(
                    isActive: $isPresented
                ) { param in
                    Text("HELLO")
                        .padding()
                }
                .systemNotificationStyle(
                    .init(backgroundColor: .blue)
                )
                .systemNotificationConfiguration(
                    .init(animation: .smooth, edge: .bottom)
                )
            }
            .onTapGesture {
                isPresented.toggle()
            }
        }
    }
    
    return Preview()
}
