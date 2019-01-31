# react-native-tensorio

Machine learning for your React Native projects, using TensorIO and TensorFlow Lite.

## Support

- iOS

## Getting started

For the time being, install directly from this repository:

`$ npm install git://github.com/doc-ai/react-native-tensorio.git --save`

### Mostly automatic installation

Link the package to your project:

`$ react-native link react-native-tensorio`

#### iOS

The react-native-tensorio package depends on the TensorIO library, which can most easily be added to your project using cocoapods ([learn more](https://cocoapods.org/)).

**Initialize Cocoapods**

If you have not already initialized cocoapods for your project, cd into your project's *ios* directory and initialize cocoapods:

```
$ pod init
```

This command creates a *Podfile* in your project's *ios* directory. 

**Fix a Cocoapods / React Native Bug**

Edit the *Podfile* and, because of a bug in how cocoapods and react native interract, remove the first block for `target MyProject-tvOSTests do`, everything from that line to the next `end` statement. It is a duplicate entry that will cause problems when you try to install the cocoapod dependencies.

You may also completey remove the entire `target 'MyProject-tvOS' do` block if you are not building for tvOS.

**Uncomment Lines**

Uncomment the `platform :ios` line and make sure it is no lower than `9.3`. Uncomment the `use_frameworks!` line.

**Add TensorIO**

Add TensorIO as a dependency under the `# Pods for MyProject ` comment:

```rb
pod `TensorIO`
```

A new podfile should like something like:

```rb
# Uncomment the next line to define a global platform for your project
platform :ios, '9.3'

target 'MyProject' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  use_frameworks!

  # Pods for MyProject

  pod 'TensorIO'

  target 'MyProjectTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

```

**Install Pods**

At the command line type:

```
$ pod install
```

This should install the TensorIO dependency as well as TensorFlow Lite and link them into your project. 

**Use the .xcworkspace file**

You should now use the *MyProject.xcworkspace* file to make changes to and build your project instead of the *MyProject.xcodeproj* file.

<!--### Manual installation

#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-tensorio` and add `RNTensorIO.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNTensorIO.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<
-->

#### Android

Android support is forthcoming.

<!-- 
1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNTensorIOPackage;` to the imports at the top of the file
  - Add `new RNTensorIOPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-tensorio'
  	project(':react-native-tensorio').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-tensorio/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-tensorio')
  	```
-->

#### Windows
<!--[Read it! :D](https://github.com/ReactWindows/react-native)-->

Windows support is unplanned.

<!-- 
1. In Visual Studio add the `RNTensorIO.sln` in `node_modules/react-native-tensorio/windows/RNTensorIO.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Tensor.IO.RNTensorIO;` to the usings at the top of the file
  - Add `new RNTensorIOPackage()` to the `List<IReactPackage>` returned by the `Packages` method 
-->

## Usage

TensorIO uses model bundles to wrap an underlying model and a description of its inputs and outputs along with any assets the model requires, such as text labels for image classification outputs ([learn more](https://github.com/doc-ai/TensorIO)). They are simply folders with the *.tfbundle* extension. You will need to add these bundles to your react native application in order to perform inference with the underlying models.

Add the TensorIO bundle to your application in Xcode. Simply drag the bundle into the project under the project's primary folder (it will be the folder with the same name as your project). Make sure to check *Copy items if needed*, select *Create folder references*, and that your build target is selected.

Then in javascript, import `NativeModules` and access `RNTensorIO` from that module. Load the model by providing its name (or path if the model is in a project subdirectory), run inference with it, and then unload it when you are done to free the underlying resources:

```javascript
import {NativeModules} from 'react-native';

var model = NativeModules.RNTensorIO;

model.load('model.tfbundle');

model.run({
  'input_name': [1,2,3,4]
}, (error, results) => {
  console.log(results)
});

model.unload();
```

A more complete description of how to use the module is forthcoming.
  