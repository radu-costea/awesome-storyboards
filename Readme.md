# A case for storyboards

There's been a while already since the Apple introduced storyboards in iOS 5. 6 Years later, people still argue about their usability. 

**Pros:**
- Visual representation of view controller graph
- Less UI files - A storyboard can embed multiple view controllers, and for each view controllers it can embed custom views, prototype cells, embedded controllers

**Cons:**
- Difficult to manage work accross a team: less files means more chances of having a conflict
- Stringly programming

As always, I don't think there is a good or bad solution, each solutions comes with some benefits and some drawbacks. It's a matter of what you can live with. I for one consider storyboards to be a good choice for most of the cases, but I can't ignore their drawbacks. 

To fix some of this drawbacks there are already out there some code generators which you can use. I tried **swiftgen** and though it worked pretty well, I didn't like the fact that it was generating a parallel structure for all the storyboards and the navigation allowed for each. I wanted something more closely coupled to my view controllers. Why not doing a code generator of our own?

But before we do that, you can take a look here if you are interested in the existing code generators: http://pretzlav.com/blog/2016/01/29/swift-codegen/

So, let's recap what were the cons:

> Difficult to manage work accross a team: less files means more chances of having a conflict 

True, which means that we could find a ballance between the number of files and the conciseness in order to achieve better results. Therefore the fix is simple: use more storyboards and reference them using storyboard references (available since iOS 9, and XCode 7)


> Stringly programming

There are more things to discuss here:

1. View controllers can be instantiated from storyboard by assigning them a storyboard identifier and then calling:
```swift
UIStoryboard(name: "<Storyboard Name>", bundle: <Bundle>).instantiateViewController(withIdentifier: "<Controller Identifier>")
```

2. Each navigation between controllers is done using a Segue. Each segue can have an identifier. And there are three methods that can / are used for navigation:

```swift
func prepareForSegue(withIdentifier identifier: String, sender: Any?)

func shouldPerformSegue(withIdentifier identifier: String) -> Bool

func prepare(for segue: UIStoryboardSegue, sender: Any?)
```

As you probably noticed, you can either prevent a navigation from happening, or you can invoke one programatically **if** you know the identifier associated to that segue. Moreover, you can inject some dependencies into the next view controller, **if** you know the identifier, and the type of the next view controller.

That's cool, but I don't want strings all over my code, and I don't want to always manually keep a 1 : 1 mapping between the identifiers provided in the storyboard and my code. And **why** should I be responsible of doing that if the storyboard itself has all the information needed?

## What would be a nicer way of doing it?

1. I would like to know to which view controllers I can navigate without going to the storyboard
2. I don't want to remember or check the storyboard for identifiers
3. I would love to be able to instantiate the view controllers without knowing the storyboard or the storyboardId I provided

## Show me code!

Let's consider each view controller a node in the navigation graph, and each segue a route:

```swift
protocol Node {
	associatedType Routes
	func shouldGo(to route: Routes) -> Bool
	func prepare(for route: Routes, destination: UIViewController)
}

extension Node where Self: UIViewController, Routes: RawRepresentable, Routes.RawValue: String {
	func go(to route: Routes) {
		performSegue(withIdentifier: route.rawValue)
	}

	func shouldGo(to route: Routes) -> Bool {
		return true
	}

	func prepare(for route: Routes, destination: UIViewController) { }
}
```

And now we can navigate from one controller to another like this:

```swift
extension MyAwesomeViewController: Node {
	enum Routes: String {
		showDetails
	}

	override func shouldPrepareForSegue(withIdentifier identifier: String) -> Bool {
		guard let route = Routes(rawValue: identifier) else { 
			return false
		}
		return shouldGo(to route: Routes)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let route = Routes(rawValue: segue.identifier) else { 
			return false
		}
		prepare(for: route, destination: segue.destination)
	}	
}

myAwesomeViewController.go(to: .showDetails)
```

Cool. Now we can know where to go from a view controller, and intercept the calls to navigate to a route by overriding: 
```swift
 shouldGo(to route: Routes) -> Bool
 ```
 and:
 ```swift
 func prepare(for route: Routes, destination: UIViewController)
 ```

We still have to write the code ourselfs, so ho do we fix that?

## Build phases

Now that we decided what we want to achieve, and how we could do it, let's add a taste of sugar by writing the script in swift.

To do so, the first line in the script file has to be this, otherwise, for iOS projects it will use the ios swift sdk instead: 
```sh
#!/usr/bin/env xcrun --sdk macosx swift
```

The storyboard file is actually an XML file. On a closer look we see the following tags:

* document
	- initialViewControllerId

* viewController:
	- customClass
	- storyboardId

* segue:
	- destinationId
	- kind
	- identifier

* viewControllerPlaceholder
	- storyboard
	- id

We'll use `XMLParser` and it's delegate methods to identify each tag and transform them into a more useful structure which will be used for generating the code.

From the tags we notice that a segue contains the id of the destination, which can be either a view controller, or a view controller placeholder. Whatever the case might be, we can identify the class of the destination view controller. This means that we could change this:

```swift
func prepare(for route: Routes, destination: UIViewController)
```
to something more useful, like this:

```swift
protocol MyAwesomeViewControllerNavigation: Node {
	func prepare(for route: Routes, destination: MyNextAwesomeViewController)
}

// And enforce MyAwesomeViewController to immplement the navigation protocol:

extension MyAwesomeViewController: MyAwesomeViewControllerNavigation { 
	enum Routes: String {
		showDetails
	}

	override func shouldPrepareForSegue(withIdentifier identifier: String) -> Bool {
		guard let route = Routes(rawValue: identifier) else { 
			return false
		}
		return shouldGo(to route: Routes)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let route = Routes(rawValue: segue.identifier) else { 
			return false
		}
		switch route {
			case .showDetails:
				if let destination = segue.destination as? MyNextAwesomeViewController {
					prepare(for: route, destination: destination)			
				}
		}
	}	
}
```

And since we also have the storyboard identifier we could also generate something like this:

```swift
extension MyAwesomeViewController {
	static func instantiateFromStoryboard() -> MyAwesomeViewController {
		return UIStoryboard(name: "StoryboardName", bundle: nil).instantiateViewController(withIdentifier: "the-identifier") as! MyAwesomeViewController
	}
}
```

## Setup

1. Add a new swift file to your project, where will be generated all the code
2. Go to build phases
3. Tap + New run script phase
4. Fill the script box with: `<path to script>/ParseStoryboards.swift <root folder> <path to generated swift file>`
5. Add as input files all the storyboards that you have in the project
6. Add as ouptut files the generated swift file
7. Drag the run script phase before Compile Sources phase 
8. Build and run


## Where to go from here?

There are a couple of things that could be improved:
1. Suport for multiple modules and add the imports accordingly
2. Consider the fact that we should not be able to call go(to: ...) for routes which denote a relationship (rootViewController, embedded view controller, etc)
3. The `instantiateFromStoryboard` might not work well if we have a custom view controller and a subclass of it when both can be instantiated from storyboard. Most of the times this you should not be doing this.
4. The Navigation protocol defines interface for all the possible destinations which implies that you need to write an implementation, even if it's an empty implementation. Most of the times this should not be the case, but in some other cases this could be anoying. Think about alternatives.

## Conclusion

I hope that you'll find the script as helpful as I do, and maybe this will encourage you to make use of storyboards more in your projects.

Thanks for reading and I'm looking forward to your feedback!
Happy coding!