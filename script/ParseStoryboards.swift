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

struct TagsRange {
    var start: String
    var end: String
}

// MARK: - Foundation Extensions

extension StringProtocol where Index == String.Index {
    func substringBetween(tagsRange: TagsRange) -> String {
        return substringBetween(startTag: tagsRange.start, and: tagsRange.end)
    }

    func rangeOfTags(_ tagsRange: TagsRange) -> Range<String.Index>? {
        return rangeOfTags(startTag: tagsRange.start, and: tagsRange.end)
    }

    func substringBetween(startTag start: String, and endTag: String) -> String {
        guard let startRange = range(of: start), let endRange = self[startRange.upperBound...].range(of: endTag) else {
            return ""
        }
        return String(self[startRange.upperBound..<endRange.lowerBound])
    }

    func rangeOfTags(startTag start: String, and endTag: String) -> Range<String.Index>? {
        guard let startRange = range(of: start), let endRange = self[startRange.upperBound...].range(of: endTag) else {
            return nil
        }
        return (startRange.lowerBound..<endRange.upperBound)
    }
}

extension String {

    mutating func replace(tags: TagsRange, string: String) {
        if let range = rangeOfTags(tags) {
            replaceSubrange(range, with: string)
        }
    }

    mutating func remove(_ tags: TagsRange, keepContent: Bool) {
        if let range = rangeOfTags(tags) {
            replaceSubrange(range, with: keepContent ? substringBetween(tagsRange: tags) : "")
        }
    }

    mutating func remove(_ tags: TagsRange, replaceContent buildNewContent: (String) -> String) {
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
        var isNavigable: Bool {
            switch self {
            case .show, .unwind, .custom:
                return true
            default:
                return false
            }
        }
    }
    var identifier: String?
    var destinationId: String?
    var kind: Kind
    var isIdentifiable: Bool { return identifier != nil }

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

    let id: String
    let storyboardIdentifier: String?
    let className: String
    var segues: [Segue] = []
    var navigable: [Segue] = []
    var identfiable: [Segue] = []

    init(attributeDict: [String : String], tag: Scene.Tag) {
        className = attributeDict["customClass"] ?? tag.baseClass
        id = attributeDict["id"] ?? ""
        storyboardIdentifier = attributeDict["storyboardIdentifier"]
    }

    mutating func addSegue(_ segue: Segue) {
        if segue.isIdentifiable { identfiable.append(segue) }
        if segue.kind.isNavigable { navigable.append(segue) }
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
    let initialControllerId: String
    var scenes: [Scene] = []

    // MARK: - Lifecycle

    init(attributeDict: [String : String], tag: Tag) {
        self.initialControllerId = attributeDict["initialViewController"] ?? ""
        self.name = ""
    }

    // MARK: - helper methods

    func destinationScene(for segue: Segue) -> Scene? {
        guard let destination = segue.destinationId else {
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
}

struct ScenePlaceholder: XMLTag {
    enum Tag: String {
        case viewControllerPlaceholder
    }

    let storyboard: String
    let id: String

    init(attributeDict: [String : String], tag: Tag) {
        storyboard = attributeDict["storyboardName"]!
        id = attributeDict["id"]!
    }
}

// MARK: - Tags definition

struct Tags {
    static var node = "<#node#>"
    static var routes = "<#routes#>"
    static var nodeInterface = TagsRange(start: "<#start_node_interface#>", end: "<#end_node_interface#>")

    // Lifecycle
    static var storyboardName = "<#storyboard_name#>"
    static var controllerClass: String = "<#controller_class#>"
    static var controllerIdentifier = "<#view_controller_identifier#>"
    static var lifecycle = TagsRange(start: "<#start_lifecycle_code#>", end: "<#end_lifecycle_code#>")
    static var lifecycleInitial = TagsRange(start: "<#start_instantiate_initial#>", end: "<#end_instantiate_initial#>")
    static var lifecycleIdentified = TagsRange(start: "<#start_instantiate_identfier#>", end: "<#end_instantiate_identfier#>")

    // Navigation
    static var navigation = TagsRange(start: "<#start_navigation_code#>", end: "<#end_navigation_code#>")
    static var destinationController = "<#destination_controller#>"
    static var segueIdentifier: String = "<#case_name#>"
    static var navigationToUniqueDestinations = TagsRange(start: "<#start_unique_destinations#>", end: "<#end_unique_destinations#>")
    static var navigationToAllIdentifiers = TagsRange(start: "<#start_repeatable#>", end: "<#end_repeatable#>")
    static var navigationToCustomDestinations = TagsRange(start: "<#start_repeatable_custom#>", end: "<#end_repeatable_custom#>")
    static var navigationToDefaultDestinations = TagsRange(start: "<#start_repeatable_default#>", end: "<#end_repeatable_default#>")
}

struct NavigationGraph {
    var nodeName = "NavigationNode"
    var routesName = "Routes"
    var storyboards = [Storyboard]()
    var placeholders = [ScenePlaceholder]()

    /// Takes the template and generates the code based on the graph structure
    ///
    /// - Parameter template: The template string to use for code generation
    /// - Returns: The generated code
    func generateCode(using template: String) -> String {
        // Common node protocol declaration from template
        var generated: String = template.substringBetween(tagsRange: Tags.nodeInterface)
        generated = generated.replacingOccurrences(of: Tags.node, with: nodeName)
        generated = generated.replacingOccurrences(of: Tags.routes, with: routesName)

        // Lifecycle section extraction from template
        let lifecycle = template.substringBetween(tagsRange: Tags.lifecycle)

        // Navigation section extraction from template
        var navigation = template.substringBetween(tagsRange: Tags.navigation)
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
            return storyboard.destinationScene(for: storyboard.initialControllerId)
        }
        return nil
    }

    private func generatedCodeForScene(_ scene: Scene, storyboard: Storyboard, lifecycle: String, navigation: String) -> String {
        var generated: String = ""
        // Lifecycle
        var lifecycleCode = lifecycle
        lifecycleCode = lifecycleCode.replacingOccurrences(of: Tags.controllerClass, with: scene.className)
        lifecycleCode = lifecycleCode.replacingOccurrences(of: Tags.storyboardName, with: storyboard.name)

        if scene.isInitial(inside: storyboard) {
            lifecycleCode.remove(Tags.lifecycleIdentified, keepContent: false)
            lifecycleCode.remove(Tags.lifecycleInitial, keepContent: true)
            generated.append(lifecycleCode)
        }

        if let storyboardId = scene.storyboardIdentifier {
            lifecycleCode = lifecycleCode.replacingOccurrences(of: Tags.controllerIdentifier, with: storyboardId)
            lifecycleCode.remove(Tags.lifecycleInitial, keepContent: false)
            lifecycleCode.remove(Tags.lifecycleIdentified, keepContent: true)
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

        navigationCode.remove(Tags.navigationToUniqueDestinations, replaceContent: { (content) -> String in
            return uniqueDestinations.map {
                content.replacingOccurrences(of: Tags.destinationController, with: $0)
                }.joined(separator: "\n")
        })
        navigationCode.remove(Tags.navigationToAllIdentifiers, replaceContent: { (content) -> String in
            return segueMapping.map {
                var replacedContent = content
                replacedContent = replacedContent.replacingOccurrences(of: Tags.segueIdentifier, with: $0.segue)
                replacedContent = replacedContent.replacingOccurrences(of: Tags.destinationController, with: $0.destination)
                replacedContent.remove(Tags.navigationToCustomDestinations, keepContent: $0.destination != "UIViewController")
                replacedContent.remove(Tags.navigationToDefaultDestinations, keepContent: $0.destination == "UIViewController")
                return replacedContent
                }.joined(separator: "\n")
        })
        return generated.appending(navigationCode)
    }
}

/// Creates the structure of a storyboard based on the XMLParserDelegate calls.
class StoryboardBuilder: NSObject, XMLParserDelegate {
    var name: String
    var storyboard: Storyboard?
    var placeholders: [ScenePlaceholder] = []
    var lastScene: Scene?

    init(name: String) {
        self.name = name
    }

    // MARK: - XMLParserDelegate

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
    struct Config {
        var template: String
        var output: String
    }

    /// The storyboards used as input for the graph
    let storyboards: [String]

    /// The graph describing the navigation for the given storyboards. On it's first use it will parse each of the storyboards
    /// And will create the navigation graph.
    lazy var graph: NavigationGraph = {
        var graph = NavigationGraph()
        storyboards.forEach { (path) in
            let url = URL(fileURLWithPath: path)
            let storyboardName = url.deletingPathExtension().lastPathComponent
            let storyboardBuilder = StoryboardBuilder(name: storyboardName)
            let xmlParser = XMLParser(contentsOf: url)
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

    // MARK: - Lifecycle

    init(storyboards: [String]) {
        self.storyboards = storyboards
    }

    // MARK: - Code generation

    /// Method which takes the configs, and for each config uses the template to generate code in the output file
    /// If the graph has not been generated yet, it will be created on first use. For the rest of the configs the already
    /// created graph will be used.
    ///
    /// - Parameter configs: An array of configs used for generating code
    /// - Throws: An error if reading of the templates or writing to output files fails
    func generateCode(using configs: [Config]) throws {
        try configs.forEach {
            let templateContent = try String(contentsOf: URL(fileURLWithPath: $0.template))
            let code = graph.generateCode(using: templateContent)
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
        case xcode = "-xcode"
    }

    let templates: [String]
    let storyboards: [String]
    let outputs: [String]

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
                case .xcode:
                    let info = ProcessInfo.processInfo
                    let paths: (String) -> [String] = { prefix in
                        let count = Int(info.environment["\(prefix)_COUNT"] ?? "0") ?? 0
                        return (0..<count).compactMap{ info.environment["\(prefix)_\($0)"] }
                    }
                    storyboards.append(contentsOf: paths("SCRIPT_INPUT_FILE"))
                    outputs.append(contentsOf: paths("SCRIPT_OUTPUT_FILE"))
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

if let arguments = Arguments(arguments: CommandLine.arguments) {
    let graphBuilder = GraphBuilder(storyboards: arguments.storyboards)
    let configs: [GraphBuilder.Config] = arguments.templates.enumerated().map{
        GraphBuilder.Config(template: $0.element, output: arguments.outputs[$0.offset])
    }
    try graphBuilder.generateCode(using: configs)
}

