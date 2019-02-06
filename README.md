# react-native-tensorio

Machine learning for your React Native projects, using TensorIO and TensorFlow Lite.

<a name="support"></a>
## Support

- iOS

<a name="getting-started"></a>
## Getting started

For the time being, install directly from this repository:

`$ npm install git+ssh://git@github.com:doc-ai/react-native-tensorio.git --save`

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

<a name="usage"></a>
## Usage

<a name="about-tensorio"></a>
### About TensorIO

TensorIO uses model bundles to wrap an underlying model and a description of its inputs and outputs along with any assets the model requires, such as text labels for image classification outputs. They are simply folders with the *.tfbundle* extension ([learn more](https://github.com/doc-ai/TensorIO)). You will need to add these bundles to your react native application in order to perform inference with the underlying models.

Every TensorIO bundle includes a description of the underlying model. Model inputs and outputs are named and indicate what kind of data they expect or produce. You must know these names in order to pass data to the model and extract results from it. From the perspective of a React Native application, you will pass an object to the model whose name-value pairs match the model's input names, and you will receive an object back from the model whose name-value pairs match the model's output names.

All this information appears in a bundle's *model.json* file. Let's have a look at the json description of a simple test model that takes a single input and produces a single output. Notice specifically the *inputs* and *outputs* fields:

```json
{
  "name": "1 in 1 out numeric test",
  "details": "Simple model with a single valued input and single valued output",
  "id": "1_in_1_out_number_test",
  "version": "1",
  "author": "doc.ai",
  "license": "",
  "model": {
    "file": "model.tflite",
    "quantized": false,
  },
  "inputs": [
    {
      "name": "x",
      "type": "array",
      "shape": [1],
    }
  ],
  "outputs": [
    {
      "name": "y",
      "type": "array",
      "shape": [1],
    }
  ]
}
```

The *inputs* and *outputs* fields tell us that this model takes a single input named *"x"* whose value is a single number and produces a single output named *"y"* whose value is also a single number. We know that the values are a single number from the shape. Let's see how to use a model like this in your own application.

<a name="basic-usage"></a>
### Basic Usage

Add a TensorIO bundle to your application in Xcode. Simply drag the bundle into the project under the project's primary folder (it will be the folder with the same name as your project). Make sure to check *Copy items if needed*, select *Create folder references*, and that your build target is selected.

Then in javascript, import `RNTensorIO  from 'react-native-tensorio`. Load the model by providing its name (or path if the model is in a project subdirectory), run inference with it, and then unload it when you are done to free the underlying resources.

Again, imagine we had a model that takes a single input named *"x"* with a single value and produces a singe output named *"y"* with a single value:

```json
"inputs": [
  {
    "name": "x",
    "type": "array",
    "shape": [1],
  }
],
"outputs": [
  {
    "name": "y",
    "type": "array",
    "shape": [1],
  }
]
```

We would use this model as follows. Notice that we pass an object to the run function whose name-value pairs match those of the model's inputs and we extract name-value pairs from the results that match those of the model's outputs:

```javascript
import RNTensorIO from 'react-native-tensorio';

RNTensorIO.load('model.tfbundle');

RNTensorIO.run({
  'x': [42]
}, (error, results) => {
  const y = results['y']
  console.log(y);
});

RNTensorIO.unload();
```

You can use any model that doesn't take image inputs or produce outputs like this. Computer vision models, however, require a little more work to use. Let's have a look.

<a name="image-models"></a>
### Image Models

React Native represents image data as a base64 encoded string. When you pass that data to a model that has image inputs you must include some additional metadata that describes the encoded image. For example, is it JPEG or PNG data, raw pixel buffer data, or a path to an image on the filesystem?

<a name="about-image-data"></a>
#### About Image Data

Models that take image inputs must receive those inputs in a pixel buffer format. A pixel buffer is an unrolled vector of bytes corresponding to the red-green-blue-alpha (RGBA) values that define the pixel representation of an image. Image models are trained on these kinds of representations and expect them for inputs.

React Native represents image data in javascript as a base64 encoded string. In order to perform inference with an image model you must provide this base64 encoded string to the run function as well as a description of the those bytes that may included metadata such as the width, height, and format of the image they represent. To run an image model you'll pack this information into a javascript object and use that object in the name-value pair you provide to the run function.

<a name="image-classification-example"></a>
#### An Image Classification Example

Let's look at a basic image classification model and see how to use it in React Native. The JSON description for the ImageNet MobilNet classification model is as follows. Again, pay special attention to the *inputs* and *outputs* fields:

```json
{
  "name": "MobileNet V2 1.0 224",
  "details": "MobileNet V2 with a width multiplier of 1.0 and an input resolution of 224x224. \n\nMobileNets are based on a streamlined architecture that have depth-wise separable convolutions to build light weight deep neural networks. Trained on ImageNet with categories such as trees, animals, food, vehicles, person etc. MobileNets: Efficient Convolutional Neural Networks for Mobile Vision Applications.",
  "id": "mobilenet-v2-100-224-unquantized",
  "version": "1",
  "author": "Andrew G. Howard, Menglong Zhu, Bo Chen, Dmitry Kalenichenko, Weijun Wang, Tobias Weyand, Marco Andreetto, Hartwig Adam",
  "license": "Apache License. Version 2.0 http://www.apache.org/licenses/LICENSE-2.0",
  "model": {
    "file": "model.tflite",
    "quantized": false,
  },
  "inputs": [
    {
      "name": "image",
      "type": "image",
      "shape": [224,224,3],
      "format": "RGB",
      "normalize": {
        "standard": "[-1,1]"
      }
    },
  ],
  "outputs": [
    {
      "name": "classification",
      "type": "array",
      "shape": [1,1000],
      "labels": "labels.txt"
    },
  ]
}
```

The *inputs* and *outputs* fields tell us that this model expects a single image input whose name is *"image"* and produces a single output whose name is *"classification"*. You don't need to worry about the image input details. TensorIO will take care of preparing an image input for the model using this information, but the output field tells you that the classification output will be a labeled list of 1000 values (1 x 1000 from the shape).

Let's see how to use this model in React Native:


```js
var data = 'data:image/jpeg;base64,' + some.data;
var orientation = RNTensorIO.imageOrientationUp;
var format = RNTensorIO.imageTypeJPG;

RNTensorIO.run({
  'image': {
    [RNTensorIO.imageKeyData]: data,
    [RNTensorIO.imageKeyFormat]: format,
    [RNTensorIO.imageKeyOrientation]: orientation
  }
}, (error, results) =>  {
  classifications = results['classification'];
  console.log(classifications);
});
```

This time we provide an object for the *"image"* name-value pair and this object contains three pieces of information: the base64 encoded string, the format of the underlying data, in this case, JPG data, and the image's orientation. The names used in this object are available on the RNTensorIO module along with the supported image orientations and image data types. They are described in more detail below.

RNTensorIO suppors image data in a number of formats. Imagine instead that we have the path to an image on the filesystem. We would run the model as follows, snd this time we'll omit the image orientation, which is assumed to be 'Up' by default:

```js
var data = '/path/to/image.png';
var format = RNTensorIO.imageTypeFile;

RNTensorIO.run({
  'image': {
    [RNTensorIO.imageKeyData]: data,
    [RNTensorIO.imageKeyFormat]: format
  }
}, (error, results) =>  {
  classifications = results['classification'];
  console.log(classifications);
});
```

Another use case might be real time pixel buffer data coming from a device camera. In this case, and on iOS, the bytes will represent raw pixel data in the BGRA format. This representation tells us nothing else about the image, so we'll also need to specify its width, height, and orientation. On iOS, pixel buffer data coming from the camera is often 640x480 and will be right oriented. We'd run the model as follows:

```js
var data; // pixel buffer data as a base64 encoded string
var format = RNTensorIO.imageTypeBGRA;
var orientation = RNTensorIO.imageOrientationRight;
var width = 640;
var height = 480;

RNTensorIO.run({
  'image': {
    [RNTensorIO.imageKeyData]: data,
    [RNTensorIO.imageKeyFormat]: format,
    [RNTensorIO.imageKeyOrientation]: orientation,
    [RNTensorIO.imageKeyWidth]: width,
    [RNTensorIO.imageKeyHeight]: height
  }
}, (error, results) =>  {
  classifications = results['classification'];
  console.log(classifications);
});
```

Image models that take image inputs will all be run in this manner.

<a name="image-outputs"></a>
#### Image Outputs

Some models will produce image outputs. In this case the value for that output will be provided to javascript as base64 encoded jpeg data. You'll likely need to prefix it as follows before being able to display it:

```js
RNTensorIO.run({
  'image': {
    // ...
  }
}, (error, results) =>  {
  var image = results['image'];
  var data = 'data:image/jpeg;base64,' + image;
});
```
  
## The RNTensorIO Module
  
Description of modules constants and functions coming...
  
TopN utility function

```js
RNTensorIO.run({
  'image': {
    [model.imageKeyData]: source,
    [model.imageKeyFormat]: model.imageTypeFile,
    [model.imageKeyOrientation]: model.imageOrientationUp
  }
}, (error, results) =>  {
  classifications = results['classification'];
  
  RNTensorIO.topN(5, 0.1, classifications, (error, top5) => {
    console.log("TOP 5", top5);
  });
});
```