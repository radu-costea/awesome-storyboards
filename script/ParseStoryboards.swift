#!/usr/bin/env xcrun --sdk macosx swift

import Foundation


enum SegueType: String {
    case segue
}

struct Segue {
    enum Kind: String {
        case embed, unwind, relationship, show, custom
    }

    var identifier: String?
    var destinationId: String?
    var kind: Kind

    init(attributeDict: [String: String]) {
        identifier = attributeDict["identifier"]
        destinationId = attributeDict["destination"]
        kind = Kind(rawValue:attributeDict["kind"] ?? "") ?? .custom
    }
}

struct Scene {
    var type: SceneType
    var className: String
    var id: String
    var segues: [Segue] = []
    var storyboardIdentifier: String?

    init(attributeDict: [String: String], type: SceneType) {
        self.type = type
        className = attributeDict["customClass"] ?? type.baseClass
        id = attributeDict["id"] ?? ""
        storyboardIdentifier = attributeDict["storyboardIdentifier"]
    }

    var identifiable: [Segue] {
        return segues.filter { [.custom, .show, .unwind, .embed].contains($0.kind) }
    }

    func swiftDescription(forStoryboard storyboard: Storyboard, storyboards: [String: Storyboard]) -> String? {
        var output: String? = nil
        if let instantiate = instantiateDescription(forStoryboard: storyboard) {
            output = instantiate
        }
        guard let conformance = navigationConformance(storyboard: storyboard, storyboards: storyboards) else {
            return output
        }
        output = output ?? ""
        output?.append(conformance)
        return output
    }

    func instantiateDescription(forStoryboard storyboard: Storyboard) -> String? {
        guard id == storyboard.initialControllerId || storyboardIdentifier != nil else {
            return nil
        }
        let instantiateInstruction: String = storyboard.initialControllerId == id ?
            "UIStoryboard(name: \"\(storyboard.name)\", bundle: nil).instantiateInitialViewController() as! \(className)" :
            "UIStoryboard(name: \"\(storyboard.name)\", bundle: nil).instantiateViewController(withIdentifier: \"\(storyboardIdentifier!)\") as! \(className)"
        return
"""

// MARK: - \(className) Lifecycle generated code

extension \(className) {
    static func instantiateFromStoryboard() -> \(className) {
        return \(instantiateInstruction)
    }
}

"""
    }

    func navigationConformance(storyboard: Storyboard, storyboards: [String: Storyboard]) -> String? {
        let destinations: [(identifier: String, destinationClass: String)] = identifiable.map { segue in
            guard let destinationId = segue.destinationId else {
                return (identifier: segue.identifier!, destinationClass: "UIViewController")
            }
            if let scene = storyboard.scenes[destinationId] {
                return (identifier: segue.identifier!, destinationClass: scene.className)
            }
            if let placeholder = storyboard.placeHolders[destinationId], let storyboard = storyboards[placeholder.storyboard] {
                return (identifier: segue.identifier!, destinationClass: storyboard.initialControllerClass)
            }
            return (identifier: segue.identifier!, destinationClass: "UIViewController")
        }
        guard !destinations.isEmpty else {
            return nil
        }
        return
"""

// MARK: - \(className) navigation generated code

\(prepareForProtocol(pairs: destinations))

extension \(className): \(className)Navigation {
    enum Routes: String {
        case \(destinations.compactMap{ $0.identifier }.joined(separator: ", "))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let route = Routes(rawValue: identifier) else { return }
        switch route {
        \(prepareCases(tabs: "        ", pairs: destinations))
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let route = Routes(rawValue: identifier) else { return false }
        return shouldPerform(route)
    }
}

"""
    }

    func prepareCases(tabs: String, pairs: [(identifier: String, destinationClass: String)]) -> String {
        return pairs.map { pair in
            guard pair.destinationClass != "UIViewController" else {
                return
"""
case .\(pair.identifier):
\(tabs)    prepare(forRoute: .\(pair.identifier), destination: segue.destination)
"""
            }
            return
"""
case .\(pair.identifier):
\(tabs)    if let destination = segue.destination as? \(pair.destinationClass) {
\(tabs)        prepare(forRoute: .\(pair.identifier), destination: destination)
\(tabs)    }
"""
        }.joined(separator: "\n\(tabs)")
    }

    func prepareForProtocol(pairs: [(identifier: String, destinationClass: String)]) -> String {
        let clases = Set<String>(pairs.map { $0.destinationClass }).sorted(by: < )
        return
"""
protocol \(className)Navigation: NavigationNode {
\(clases.map{ "    func prepare(forRoute route: Routes, destination: \($0))"}.joined(separator:"\n"))
}
"""
    }
}

enum DocumentType: String {
    case document
}

struct Document {
    var initialControllerId: String

    init(attributeDict: [String: String]) {
        initialControllerId = attributeDict["initialViewController"] ?? ""
    }
}

enum SceneType: String {
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

enum ScenePlaceholderType: String {
    case viewControllerPlaceholder
}

struct ScenePlaceholder {
    var storyboard: String
    var id: String

    init(attributeDict: [String: String]) {
        storyboard = attributeDict["storyboardName"]!
        id = attributeDict["id"]!
    }
}

struct Storyboard {
    var name: String
    var scenes: [String: Scene] = [:]
    var initialControllerId: String
    var initialControllerClass: String { return scenes[initialControllerId]!.className }
    var placeHolders: [String: ScenePlaceholder] = [:]

    init(name: String, document: Document) {
        self.name = name
        self.initialControllerId = document.initialControllerId
    }

    func output(storyboards: [String: Storyboard]) -> String {
        return scenes
            .filter { $0.value.className != $0.value.type.baseClass }
            .sorted(by: { $0.value.className < $1.value.className })
            .compactMap {
                $0.value.swiftDescription(
                    forStoryboard: self,
                    storyboards: storyboards
                )
            }.joined()
    }
}

class StoryboardBuilder: NSObject, XMLParserDelegate {
    var parsedStoryboard: Storyboard?
    var storyboard: String
    var current: Scene? = nil

    init(storyboard: String) {
        self.storyboard = storyboard
    }

    public func parserDidStartDocument(_ parser: XMLParser) {
        current = nil
    }

    public func parserDidEndDocument(_ parser: XMLParser) { }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if let _ = DocumentType(rawValue: elementName) {
            let document = Document(attributeDict: attributeDict)
            parsedStoryboard = Storyboard(name: storyboard, document: document)
        } else if let _ = ScenePlaceholderType(rawValue: elementName) {
            let placeholder = ScenePlaceholder(attributeDict: attributeDict)
            parsedStoryboard?.placeHolders[placeholder.id] = placeholder
        } else if let sceneTag = SceneType(rawValue: elementName) {
            current = Scene(attributeDict: attributeDict, type: sceneTag)
        } else if let _ = SegueType(rawValue: elementName) {
            let segue = Segue(attributeDict: attributeDict)
            current?.segues.append(segue)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let _ = SceneType(rawValue: elementName), let current = current {
            parsedStoryboard?.scenes[current.id] = current
            self.current = nil
        }
    }
}

func searchForStoryboardsIn(root: String, outputFile: String) throws {
    let fileManager = FileManager.default
    let subpaths = try fileManager.subpathsOfDirectory(atPath: root)
    var output =
"""
//
//  Autogenerated code. Do not change.
//

import UIKit
import Foundation

protocol NavigationNode {
    associatedtype Routes
    func shouldPerform(_ connection: Routes) -> Bool
}

extension NavigationNode where Self: UIViewController, Routes: RawRepresentable, Routes.RawValue == String {

    /// Navigates to a route
    ///
    /// - Parameter route: The connection to navigate to
    func goTo(_ route: Routes)  {
        performSegue(withIdentifier: route.rawValue, sender: nil)
    }

    /// Default implementation for checking if a route should be invoked
    ///
    /// - Parameter route: The route to follow
    /// - Returns: true if the route is allowed
    func shouldPerform(_ route: Routes) -> Bool {
        return true
    }
}

"""
    var storyboards: [String: Storyboard] = [:]

    for subpath in subpaths where NSString(string: subpath).pathExtension == "storyboard" {
        if let parsed = parseStoryboard(path: NSString(string: root).appendingPathComponent(subpath)) {
            storyboards[parsed.name] = parsed
        }
    }

    output.append(storyboards.sorted(by: { $0.key < $1.key }).map{ $0.value.output(storyboards: storyboards) }.joined(separator: "") )
    print(output)
    let url = URL(fileURLWithPath: outputFile)
    try output.write(to: url, atomically: true, encoding: .utf8)
}

func parseStoryboard(path: String) -> Storyboard? {
    let url = URL(fileURLWithPath: path)
    let parser = XMLParser(contentsOf: url)
    let delegate = StoryboardBuilder(storyboard: NSString(string: NSString(string: path).lastPathComponent).deletingPathExtension)
    parser?.delegate = delegate
    if let parser = parser {
        if parser.parse() {
            return delegate.parsedStoryboard
        } else {
            print(String(describing: parser.parserError?.localizedDescription))
        }
    }
    return nil
}

try searchForStoryboardsIn(root: CommandLine.arguments[1], outputFile: CommandLine.arguments[2])
