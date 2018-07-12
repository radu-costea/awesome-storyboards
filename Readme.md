# Awesome storyboards

Storyboards are awesome, but they do involve some repetitive work and of course, stringly programming.

Awesome storyboards helps you adding some type safetyness, removing stringly programming, and drop some of the repetitive work since it generates the code for you.

## How it works?

It scans all the storyboards passed as input files, and creates a graph storying the relvant information from the storyboards. Based on that graph, you can generate code for the navigation using a template for the output.
In the template there are certain keywords which denote either a repeating region (marked by two identifiers - for start and for end), or keywords which will be replaced with info from the storyboards.

Here is how the template we propose look like:

```swift
<#start_node_interface#>
//
//  Autogenerated code. Please do not change.
//
//  Copyright © 2018 SoftVision. All rights reserved.
//
//

import UIKit
import Foundation

protocol <#node#> {
    associatedtype <#routes#>
    func shouldPerform(_ connection: <#routes#>) -> Bool
}

extension <#node#> where Self: UIViewController, <#routes#>: RawRepresentable, <#routes#>.RawValue == String {

    /// Navigates to a route
    ///
    /// - Parameter route: The connection to navigate to
    func go(to route: <#routes#>)  {
        performSegue(withIdentifier: route.rawValue, sender: nil)
    }

    /// Default implementation for checking if a route should be invoked
    ///
    /// - Parameter route: The route to follow
    /// - Returns: true if the route is allowed
    func shouldPerform(_ route: <#routes#>) -> Bool {
        return true
    }
}

<#end_node_interface#><#start_lifecycle_code#>// MARK: - <#controller_class#> Lifecycle generated code

extension <#controller_class#> {
    static func instantiateFromStoryboard() -> <#controller_class#> {
        return UIStoryboard(name: "<#storyboard_name#>", bundle: nil).<#start_instantiate_initial#>instantiateInitialViewController()<#end_instantiate_initial#><#start_instantiate_identfier#>instantiateViewController(withIdentifier: "<#view_controller_identifier#>")<#end_instantiate_identfier#> as! <#controller_class#>
    }
}

<#end_lifecycle_code#><#start_navigation_code#>// MARK: - <#controller_class#> navigation generated code

protocol <#controller_class#>Navigation: <#node#> {
<#start_unique_destinations#>    func prepare(forRoute route: <#routes#>, destination: <#destination_controller#>)<#end_unique_destinations#>
}

extension <#controller_class#>: <#controller_class#>Navigation {
    enum <#routes#>: String {
<#start_repeatable#>        case <#case_name#><#end_repeatable#>
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let route = <#routes#>(rawValue: identifier) else {
            return
        }
        switch route {
<#start_repeatable#>        case .<#case_name#>:
<#start_repeatable_custom#>            if let destination = segue.destination as? <#destination_controller#> {
                prepare(forRoute: route, destination: destination)
            }<#end_repeatable_custom#><#start_repeatable_default#>            prepare(forRoute: route, destination: segue.destination)<#end_repeatable_default#><#end_repeatable#>
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let route = <#routes#>(rawValue: identifier) else {
            return false
        }
        return shouldPerform(route)
    }
}

<#end_navigation_code#>
```

And here is the output for a storyboard with only one segue:

```swift
//
//  Autogenerated code. Please do not change.
//
//  Copyright © 2018 SoftVision. All rights reserved.
//
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
    func go(to route: Routes)  {
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

// MARK: - ViewController Lifecycle generated code

extension ViewController {
    static func instantiateFromStoryboard() -> ViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! ViewController
    }
}

// MARK: - ViewController navigation generated code

protocol ViewControllerNavigation: NavigationNode {
    func prepare(forRoute route: Routes, destination: UINavigationController)
}

extension ViewController: ViewControllerNavigation {
    enum Routes: String {
        case showNav22
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let route = Routes(rawValue: identifier) else {
            return
        }
        switch route {
        case .showNav22:
            if let destination = segue.destination as? UINavigationController {
                prepare(forRoute: route, destination: destination)
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let route = Routes(rawValue: identifier) else {
            return false
        }
        return shouldPerform(route)
    }
}

```

## How to install?

1. Add a new swift file to your project, where will be generated all the code
2. Go to build phases
3. Tap + New run script phase
4. Fill the script box with: 

```sh
# unlock all output files
for INFILE in ${!SCRIPT_OUTPUT_FILE_*};
do
    I=${!INFILE};
    if [[ -e "$I" ]];
    then
        chflags nouchg "$I";
    fi
done
#run the script
<path to script>/ParseStoryboards.swift -xcode -t <path to template file>
#lock output files
for INFILE in ${!SCRIPT_OUTPUT_FILE_*};
do
    I=${!INFILE};
    if [[ -e "$I" ]];
    then
        chflags uchg "$I";
    fi
done

```

5. Add as input files all the storyboards that you have in the project
6. Add as ouptut files the generated swift file
7. Drag the run script phase before Compile Sources phase 
8. Build and run

## Usage

The script takes the following arguments:
* "-xcode" - this argument tells the script that it should add all the input files from the `SCRIPT_INPUT_FILE_<number>`, and the same for output files from `SCRIPT_OUTPUT_FILE_<number>`
* "-t" - arguments following this should be absolute paths to the templates used
* "-o" - arguments following this should be absolute paths to the output files
* "-s" - arguments following this shoudl be absolute paths to the storyboards used

You can combine -xcode and -s respectively -o, and the script will use both -xcode input / output files and the ones you manually specified
**Note**: Each output file shoult correspond to a template. So, you have to make sure you have as many output files as templates specified.

## Creating custom templates

As you probably noticed, there are a couple of predefined tags used in templates, which will be replaced accordingly:

* Keyword tags:
	-  "<#node#>" - The Node Protocol if you define one
    -  "<#routes#>" - The Routes associated type
    -  "<#storyboard_name#>" - The storyboard name 
    -  "<#controller_class#>" - The current controller class
    -  "<#view_controller_identifier#>" - The current controller storyboard identifier
    -  "<#destination_controller#>" - The destination controller in a navigation
    -  "<#case_name#>" - The segue identifier

* Section tags:
	-  "<#start_node_interface#>", "<#end_node_interface#>" - defines the section for declaring the Node protocol, or any other stuff which should be only added once
    -  "<#start_lifecycle_code#>", "<#end_lifecycle_code#>" - defines the lifecycle section. This section will not be added if a view controller is neither the initial view controller, or has a storyboardIdentifier
    -  "<#start_instantiate_initial#>", "<#end_instantiate_initial#>" - section will be used when the view controller is the initial view controller in a storyboard
    -  "<#start_instantiate_identfier#>", "<#end_instantiate_identfier#>" - section will be used when the view controller has a storyboard identifier
    -  "<#start_navigation_code#>", "<#end_navigation_code#>" - defines the section which will include the navigation code. If none of the view controller segues doesn't have an identifier this section will not be added
    -  "<#start_unique_destinations#>", "<#end_unique_destinations#>" - this section will be called for each of the destination view controllers, only once for a destination view controller type
    -  "<#start_repeatable#>", "<#end_repeatable#>" - this section will be called for each segue identifier 
    -  "<#start_repeatable_custom#>", "<#end_repeatable_custom#>" - this section will be called only for custom view controllers destinations (any subclass of UIViewController)
    -  "<#start_repeatable_default#>", "<#end_repeatable_default#>" - this section will be called only for UIViewController destinations (or when the destination type cannot be deduced)


