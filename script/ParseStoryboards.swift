#!/usr/bin/env xcrun --sdk macosx swift
//
//  main.swift
//  Parser
//
//  Created by radu.costea on 7/10/18.
//  Copyright © 2018 Softvision. All rights reserved.
//

import Foundation

// MARK: - Tags used to delimitate code

protocol TagsRange {
    static var start: String { get }
    static var end: String { get }
}

// MARK: - Foundation Extensions

extension StringProtocol where Index == String.Index {
    func substringBetween<T: TagsRange>(tagsRange: T.Type) -> String {
        return substringBetween(startTag: T.start, and: T.end)
    }

    func rangeOfTags<T: TagsRange>(_ tags: T.Type) -> Range<String.Index>? {
        return rangeOfTags(startTag: T.start, and: T.end)
    }

    func substringBetween(startTag start: String, and endTag: String) -> String {
        if let startRange = range(of: start), let endRange = self[startRange.upperBound...].range(of: endTag) {
            return String(self[startRange.upperBound..<endRange.lowerBound])
        }
        return ""
    }

    func rangeOfTags(startTag start: String, and endTag: String) -> Range<String.Index>? {
        if let startRange = range(of: start), let endRange = self[startRange.upperBound...].range(of: endTag) {
            return (startRange.lowerBound..<endRange.upperBound)
        }
        return nil
    }
}

extension String {
    mutating func replace<T: TagsRange>(tags: T.Type, string: String) {
        if let range = rangeOfTags(T.self) {
            replaceSubrange(range, with: string)
        }
    }

    mutating func remove<T: TagsRange>(_ tags: T.Type, keepContent: Bool) {
        if let range = rangeOfTags(tags) {
            replaceSubrange(range, with: keepContent ? substringBetween(tagsRange: tags) : "")
        }
    }

    mutating func remove<T: TagsRange>(_ tags: T.Type, replaceContent buildNewContent: (String) -> String) {
        var idx = startIndex
        while let range = self[idx...].rangeOfTags(tags) {
            let content = substringBetween(tagsRange: tags)
            let toReplace = buildNewContent(content)
            replaceSubrange(range, with: toReplace)
            idx = self.index(idx, offsetBy: toReplace.count)
        }
    }
}

// MARK: - XML Tags structures

protocol XMLTag {
    associatedtype Tag
    init(attributeDict: [String: String], tag: Tag)
}

struct Segue: XMLTag {
    enum Tag: String {
        case segue
    }
    enum Kind: String {
        case embed, unwind, relationship, show, custom
    }
    var identifier: String?
    var destinationId: String?
    var kind: Kind

    init(attributeDict: [String : String], tag: Segue.Tag) {
        identifier = attributeDict["identifier"]
        destinationId = attributeDict["destination"]
        kind = Kind(rawValue:attributeDict["kind"] ?? "") ?? .custom
    }
}

struct Scene: XMLTag {
    enum Tag: String {
        case viewController, pageViewController, tableViewController, collectionViewController, navigationController, tabBarController

        var baseClass: String {
            switch self {
            case .viewController: return "UIViewController"
            case .pageViewController: return "UIPageViewController"
            case .tableViewController: return "UITableViewController"
            case .collectionViewController: return "UICollectionViewController"
            case .navigationController: return "UINavigationController"
            case .tabBarController: return "UITabBarController"
            }
        }
    }

    var id: String
    var storyboardIdentifier: String?
    var className: String
    var segues: [Segue] = []
    var navigable: [Segue] {
        return segues.filter { [Segue.Kind.custom, Segue.Kind.show, Segue.Kind.unwind].contains($0.kind) }
    }
    var identfiable: [Segue] {
        return segues.filter { segue in segue.identifier != nil }
    }

    init(attributeDict: [String : String], tag: Scene.Tag) {
        className = attributeDict["customClass"] ?? tag.baseClass
        id = attributeDict["id"] ?? ""
        storyboardIdentifier = attributeDict["storyboardIdentifier"]
    }

    mutating func addSegue(_ segue: Segue) {
        segues.append(segue)
    }

    func isInitial(inside storyboard: Storyboard) -> Bool {
        return storyboard.initialControllerId == id
    }
}

struct Storyboard: XMLTag {
    enum Tag: String {
        case document
    }
    var name: String
    var initialControllerId: String
    var scenes: [Scene] = []

    func destinationScene(for segue: Segue) -> Scene? {
        guard let destination = segue.destinationId else {
            print("destination is nil")
            return nil
        }
        return destinationScene(for: destination)
    }

    func destinationScene(for identifier: String) -> Scene? {
        return scenes.first(where: { $0.id == identifier })
    }

    mutating func addScene(_ scene: Scene) {
        scenes.append(scene)
    }

    init(attributeDict: [String : String], tag: Tag) {
        self.initialControllerId = attributeDict["initialViewController"] ?? ""
        self.name = ""
    }
}

struct ScenePlaceholder: XMLTag {
    enum Tag: String {
        case viewControllerPlaceholder
    }

    var storyboard: String
    var id: String

    init(attributeDict: [String : String], tag: Tag) {
        storyboard = attributeDict["storyboardName"]!
        id = attributeDict["id"]!
    }
}

// MARK: - Tags definition

struct Tags {
    static var controllerClass: String = "<#controller_class#>"
    static var node = "<#node#>"
    static var routes = "<#routes#>"
    struct NodeInterface: TagsRange {
        static var start: String = "<#start_node_interface#>"
        static var end: String = "<#end_node_interface#>"
    }
    struct NodeLifecycle: TagsRange {
        static var start: String = "<#start_lifecycle_code#>"
        static var end: String = "<#end_lifecycle_code#>"
        static var storyboard: String = "<#storyboard_name#>"
        static var identifier: String = "<#view_controller_identifier#>"

        struct Initial: TagsRange {
            static var start: String = "<#start_instantiate_initial#>"
            static var end: String = "<#end_instantiate_initial#>"
        }

        struct Identified: TagsRange {
            static var start: String = "<#start_instantiate_identfier#>"
            static var end: String = "<#end_instantiate_identfier#>"
        }
    }

    struct Navigation: TagsRange {
        static var start: String = "<#start_navigation_code#>"
        static var end: String = "<#end_navigation_code#>"
        static var destinationController: String = "<#destination_controller#>"
        static var caseName: String = "<#case_name#>"

        struct UniqueDestinations: TagsRange {
            static var start: String = "<#start_unique_destinations#>"
            static var end: String = "<#end_unique_destinations#>"
        }

        struct Repeatable: TagsRange {
            static var start = "<#start_repeatable#>"
            static var end = "<#end_repeatable#>"

            struct DefaultDestination: TagsRange {
                static var start = "<#start_repeatable_default#>"
                static var end = "<#end_repeatable_default#>"
            }

            struct CustomDestination: TagsRange {
                static var start = "<#start_repeatable_custom#>"
                static var end = "<#end_repeatable_custom#>"
            }
        }
    }
}

struct NavigationGraph {
    var nodeName = "NavigationNode"
    var routesName = "Routes"
    var storyboards: [Storyboard] = []
    var placeholders: [ScenePlaceholder] = []

    init() { }

    /// <#Description#>
    ///
    /// - Parameter template: <#template description#>
    /// - Returns: <#return value description#>
    func generateCode(for template: String) -> String {
        // Common node protocol declaration from template
        var generated: String = template.substringBetween(tagsRange: Tags.NodeInterface.self)
        generated = generated.replacingOccurrences(of: Tags.node, with: nodeName)
        generated = generated.replacingOccurrences(of: Tags.routes, with: routesName)

        // Lifecycle section extraction from template
        let lifecycle = template.substringBetween(tagsRange: Tags.NodeLifecycle.self)

        // Navigation section extraction from template
        var navigation = template.substringBetween(tagsRange: Tags.Navigation.self)
        navigation = navigation.replacingOccurrences(of: Tags.node, with: nodeName)
        navigation = navigation.replacingOccurrences(of: Tags.routes, with: routesName)

        // Storyboards should be sorted so that the generated code is the same each time
        let sorted = storyboards.sorted(by: { $0.name < $1.name })
        let scenes = sorted.flatMap{ storyboard in storyboard.scenes.map{ (scene: $0, storyboard: storyboard)} }
        return generated.appending(
            scenes.map{
                generatedCodeForScene($0.scene, storyboard: $0.storyboard, lifecycle: lifecycle, navigation: navigation)
            }.joined()
        )
    }

    // MARK: - Private methods

    private func storyboard(forPlaceholder placeholder: ScenePlaceholder) -> Storyboard? {
        return storyboards.first(where: { $0.name == placeholder.storyboard })
    }

    private func placeholder(for segue: Segue) -> ScenePlaceholder? {
        guard let destinationId = segue.identifier else {
            return nil
        }
        return placeholders.first(where: { $0.id == destinationId })
    }

    private func destinationScene(for segue: Segue, owningStoryboard storyboard: Storyboard) -> Scene? {
        if let scene = storyboard.destinationScene(for: segue) {
            return scene
        }
        if let placeholder = self.placeholder(for: segue), let storyboard = self.storyboard(forPlaceholder: placeholder) {
            return storyboard.destinationScene(for: storyboard.initialControllerId)!
        }
        return nil
    }

    private func generatedCodeForScene(_ scene: Scene, storyboard: Storyboard, lifecycle: String, navigation: String) -> String {
        var generated: String = ""
        // Lifecycle
        var lifecycleCode = lifecycle
        lifecycleCode = lifecycleCode.replacingOccurrences(of: Tags.controllerClass, with: scene.className)
        lifecycleCode = lifecycleCode.replacingOccurrences(of: Tags.NodeLifecycle.storyboard, with: storyboard.name)

        if scene.isInitial(inside: storyboard) {
            lifecycleCode.remove(Tags.NodeLifecycle.Identified.self, keepContent: false)
            lifecycleCode.remove(Tags.NodeLifecycle.Initial.self, keepContent: true)
            generated.append(lifecycleCode)
        }

        if let storyboardId = scene.storyboardIdentifier {
            lifecycleCode = lifecycleCode.replacingOccurrences(of: Tags.NodeLifecycle.identifier, with: storyboardId)
            lifecycleCode.remove(Tags.NodeLifecycle.Initial.self, keepContent: false)
            lifecycleCode.remove(Tags.NodeLifecycle.Identified.self, keepContent: true)
            generated.append(lifecycleCode)
        }

        // Navigation
        if scene.identfiable.isEmpty {
            return generated
        }

        var navigationCode = navigation
        navigationCode = navigationCode.replacingOccurrences(of: Tags.controllerClass, with: scene.className)

        let segueMapping: [(segue: String, destination: String)] = scene.identfiable.map {
            guard let scene = destinationScene(for: $0, owningStoryboard: storyboard) else {
                return (segue: $0.identifier!, destination: "UIViewController")
            }
            return (segue: $0.identifier!, destination: scene.className)
            }.sorted(by: { $0.destination < $1.destination} )

        // Protocol methods declarations
        let uniqueDestinations = Set<String>(segueMapping.map{ $0.destination }).sorted(by: < )

        navigationCode.remove(Tags.Navigation.UniqueDestinations.self, replaceContent: { (content) -> String in
            return uniqueDestinations.map {
                content.replacingOccurrences(of: Tags.Navigation.destinationController, with: $0)
                }.joined(separator: "\n")
        })
        navigationCode.remove(Tags.Navigation.Repeatable.self, replaceContent: { (content) -> String in
            return segueMapping.map {
                var replacedContent = content
                replacedContent = replacedContent.replacingOccurrences(of: Tags.Navigation.caseName, with: $0.segue)
                replacedContent = replacedContent.replacingOccurrences(of: Tags.Navigation.destinationController, with: $0.destination)
                replacedContent.remove(Tags.Navigation.Repeatable.CustomDestination.self, keepContent: $0.destination != "UIViewController")
                replacedContent.remove(Tags.Navigation.Repeatable.DefaultDestination.self, keepContent: $0.destination == "UIViewController")
                return replacedContent
                }.joined(separator: "\n")
        })
        return generated.appending(navigationCode)
    }
}

class StoryboardBuilder: NSObject, XMLParserDelegate {
    var name: String
    var storyboard: Storyboard?
    var placeholders: [ScenePlaceholder] = []
    var lastScene: Scene?

    init(name: String) {
        self.name = name
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let tag = Storyboard.Tag(rawValue: elementName) {
            storyboard = Storyboard(attributeDict: attributeDict, tag: tag)
            storyboard?.name = name
        } else if let tag = ScenePlaceholder.Tag(rawValue: elementName) {
            placeholders.append(ScenePlaceholder(attributeDict: attributeDict, tag: tag))
        } else if let tag = Scene.Tag(rawValue: elementName) {
            lastScene = Scene(attributeDict: attributeDict, tag: tag)
        } else if let tag = Segue.Tag(rawValue: elementName) {
            lastScene?.addSegue(Segue(attributeDict: attributeDict, tag: tag))
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let _ = Scene.Tag(rawValue: elementName), let current = lastScene {
            storyboard?.addScene(current)
            lastScene = nil
        }
    }
}

class GraphBuilder {
    var storyboards: [String]
    lazy var graph: NavigationGraph = {
        var graph = NavigationGraph()
        storyboards.forEach { (path) in
            let storyboardName = NSString(string: NSString(string: path).lastPathComponent).deletingPathExtension
            let storyboardBuilder = StoryboardBuilder(name: storyboardName)
            let xmlParser = XMLParser(contentsOf: URL(fileURLWithPath: path))
            xmlParser?.delegate = storyboardBuilder
            if let result = xmlParser?.parse(), result {
                if let storyboard = storyboardBuilder.storyboard {
                    graph.storyboards.append(storyboard)
                }
                graph.placeholders.append(contentsOf: storyboardBuilder.placeholders)
            }
        }
        return graph
    }()

    init(storyboards: [String]) {
        self.storyboards = storyboards
    }

    func generateCodeUsingTemplates(_ templates: [(template: String, output: String)]) throws {
        try templates.forEach {
            let templateContent = try String(contentsOf: URL(fileURLWithPath: $0.template))
            let code = graph.generateCode(for: templateContent)
            print(code)
            print("writing generated code to \($0.output)")
            try code.write(toFile: $0.output, atomically: false, encoding: .utf8)
        }
    }
}

struct Arguments {
    enum Prefix: String {
        case storyboards = "-s"
        case templates = "-t"
        case outputs = "-o"
    }

    var templates: [String]
    var storyboards: [String]
    var outputs: [String]

    init?(arguments: [String]) {
        var templates = [String]()
        var storyboards = [String]()
        var outputs = [String]()
        var addPath: ((String) -> Void)? = nil
        arguments.forEach { argument in
            if let prefix = Prefix(rawValue: argument) {
                switch prefix {
                case .storyboards: addPath = { storyboards.append($0 ) }
                case .outputs: addPath = { outputs.append($0 ) }
                case .templates: addPath = { templates.append($0 ) }
                }
            } else {
                addPath?(argument)
            }
        }
        if [storyboards, outputs, templates].contains(where: { $0.isEmpty }) {
            print("invalid number of arguments. Please provide at least one storyboard, one template and one output file")
            return nil
        }
        if templates.count != outputs.count {
            print("invalid number of arguments. The templates number must be equal to the output files number")
            return nil
        }
        self.storyboards = storyboards
        self.templates = templates
        self.outputs = outputs
    }
}

var storyboards = [String]()
var templates = [String]()
var outputs = [String]()

if let arguments = Arguments(arguments: CommandLine.arguments) {
    let graphBuilder = GraphBuilder(storyboards: arguments.storyboards)
    try graphBuilder.generateCodeUsingTemplates(arguments.templates.enumerated().map{ (template: $0.element, output: arguments.outputs[$0.offset]) })
}

