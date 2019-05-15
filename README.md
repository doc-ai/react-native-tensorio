# react-native-tensorio

Machine learning for your React Native projects, using TensorIO and TensorFlow Lite. See our example project, [TensorIOExample](https://github.com/doc-ai/react-native-tensorio-example).

<a name="support"></a>
## Support

- iOS

<a name="getting-started"></a>
## Getting started

### Mostly automatic installation

Install the package into your project:

```bash
$ npm install react-native-tensorio --save
```

And link the package to your project:

```bash
$ react-native link react-native-tensorio
```

#### iOS

The react-native-tensorio package depends on the TensorIO library, which can most easily be added to your project using cocoapods ([learn more](https://cocoapods.org/)).

##### Initialize Cocoapods

If you have not already initialized cocoapods for your project, cd into your project's *ios* directory and initialize cocoapods:

```
$ pod init
```

This command creates a *Podfile* in your project's *ios* directory. 

##### Fix a Cocoapods / React Native Bug

Edit the *Podfile* and, because of a bug in how cocoapods and React Native interact, remove the first block for `target MyProject-tvOSTests do`, everything from that line to the `end` statement. It is a duplicate entry that will cause problems when you try to install the cocoapod dependencies.

You may also completey remove the entire `target 'MyProject-tvOS' do` block if you are not building for tvOS.

##### Uncomment Lines

Uncomment the `platform :ios` line and make sure it is no lower than `9.3`. Uncomment the `use_frameworks!` line.

##### Add TensorIO

Add TensorIO as a dependency under the `# Pods for MyProject ` comment:

```rb
pod 'TensorIO'
pod 'TensorIO/TFLite'
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
  pod 'TensorIO/TFLite'

  target 'MyProjectTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

```

##### Install Pods

At the command line type:

```
$ pod install
```

This should install the TensorIO dependency as well as TensorFlow Lite and link them into your project. 

##### Use the .xcworkspace file

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

<a name="usage"></a>
## Usage

<a name="about-tensorio"></a>
### About TensorIO

TensorIO uses model bundles to wrap an underlying model and a description of its inputs and outputs along with any assets the model requires, such as text labels for image classification outputs. They are simply folders with the *.tfbundle* extension ([learn more](https://github.com/doc-ai/TensorIO)). You will need to add these bundles to your React Native application in order to perform inference with the underlying models.

Every TensorIO bundle includes a description of the underlying model. Model inputs and outputs are named and indicate what kind of data they expect or produce. You must know these names in order to pass data to the model and extract results from it. From the perspective of a React Native application, you will pass an object to the model whose name-value pairs match the model's input names, and you will receive an object back from the model whose name-value pairs match the model's output names.

All this information appears in a bundle's *model.json* file. Let's have a look at the json description of a simple test model that takes a single input and produces a single output. Notice specifically the *inputs* and *outputs* fields:

```json
{
  "name": "1 in 1 out numeric test",
  "details": "Simple model with a single valued input and single valued output",
  "id": "1_in_1_out_number_test",
  "version": "1",
  "author": "doc.ai",
  "license": "Apache 2.0",
  "model": {
    "file": "model.tflite",
    "backend": "tflite",
    "quantized": false
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

Then in javascript, import `RNTensorIO  from 'react-native-tensorio`. Load the model by providing its name or a fully qualified path, run inference with it, and unload the model when you are done to free the underlying resources.

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

You can use any model that doesn't take image inputs like this. Computer vision models, however, require a little more work to use. Let's have a look.

<a name="image-models"></a>
### Image Models

React Native represents image data as a base64 encoded string. When you pass that data to a model that has image inputs you must include some additional metadata that describes the encoded image. For example, is it JPEG or PNG data, raw pixel buffer data, or a path to an image on the filesystem?

<a name="about-image-data"></a>
#### About Image Data

Models that take image inputs must receive those inputs in a pixel buffer format. A pixel buffer is an unrolled vector of bytes corresponding to the red-green-blue (RGB) values that define the pixel representation of an image. Image models are trained on these kinds of representations and expect them for inputs.

React Native represents image data in javascript as a base64 encoded string. In order to perform inference with an image model you must provide this base64 encoded string to the run function as well as a description of the those bytes that may included metadata such as the width, height, and format of the image they represent. To run an image model you'll pack this information into a javascript object and use that object in one of the name-value pairs you provide to the run function.

<a name="image-classification-example"></a>
#### An Image Classification Example

Let's look at a basic image classification model and see how to use it in React Native. The JSON description for the ImageNet MobileNet classification model is as follows. Again, pay special attention to the *inputs* and *outputs* fields:

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
    "backend": "tflite",
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

The *inputs* and *outputs* fields tell us that this model expects a single image input whose name is *"image"* and produces a single output whose name is *"classification"*. You don't need to worry about the image input details. TensorIO will take care of preparing an image input for the model using this information. But the output field tells you that the classification output will be a labeled list of 1000 values (1 x 1000 from the shape).

Let's see how to use this model in React Native. Assuming we have some base64 encoded JPEG data:


```js
var data = 'data:image/jpeg;base64,' + some.data;
var orientation = RNTensorIO.imageOrientationUp;
var format = RNTensorIO.imageTypeJPEG;

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

This time we provide an object for the *"image"* name-value pair and this object contains three pieces of information: the base64 encoded string, the format of the underlying data, in this case, JPEG data, and the image's orientation. The names used in this object are exported by the RNTensorIO module along with the supported image orientations and image data types. These are all described in more detail below.

RNTensorIO supports image data in a number of formats. Imagine instead that we have the path to an image on the filesystem. We would run the model as follows, and this time we'll omit the image orientation, which is assumed to be 'Up' by default:

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

All image models that take image inputs will be run in this manner.

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
  
Listed below are the functions and constants exported by this module.

### Functions

#### load(path)

Loads the model at the given path. If the path is a relative path the model will be loaded from the application bundle.

Usage:

```js
RNTensorIO.load('model.tfbundle');
```

#### run(input, callback)

Perform inference with the loaded model on the input. 

The input must be a javascript object whose name-value pairs match the names expected by the underlying model's inputs and which are described in the model bundle's *model.json* file.

The callback has the signature `(error, results) => { ... }`. If there was a problem performing inference, error will be set to a string value describing the problem. It will be null otherwise. Results will be a javascript object whose name-value pairs match the names of the model's outputs and which are described in the model bundle's *model.json* file. If there was an error, results will be null.

Usage:

```js
RNTensorIO.run({
  'input': [1]
}, (error, results) => {
  if (error) {
    // handle error
  } else {
    console.log(results);
  }
});
```

#### run(input, callback)

Perform model training on the inputs provided. 

**Important:** Please ensure that the training model is loaded before this method is called. For the moment, the model used
for inference is different from the one used for training.  

The input must be a javascript object whose name-value pairs match the names expected by the underlying model's inputs and which are described in the model bundle's *model.json* file.

The callback has the signature `(error, results) => { ... }`. If there was a problem performing inference, error will be set to a string value describing the problem. It will be null otherwise.

Usage:

```js
RNTensorIO.train([{
  'input': [1]
  'label': [0]
}], (error, results) => {
  if (error) {
    // handle error
  } else {
    console.log(results);
  }
});
```

#### unload()

Unloads the loaded model and frees the underlying resources. Explicitly unload models when you are done with them to aggressively manage the application's memory footprint.

Usage:

```js
RNTensorIO.unload()
```

#### topN(count, threshold, classifications, callback)

A utility function for image classification models that filters for the results with the highest probabilities above a given threshold. 

Image classification models are often capable of recognizing hundreds or thousands of items and return what is called a softmax probability distribution that describes the likelihood that a recognizable item appears in the image. Often we do not want to know the entire probabilty distribution but only want to know which items have the highest probability of being in the image. Use this function to filter for those items.

Count is the number of items you would like to be returned.

Threshold is the minimum probability value an item should have in order to be returned. If there are fewer than count items above this probability, only that many items will be returned.

Classifications is the output of a classification model.

The callback has the signature `(error, results) => { ... }`. Error will always be null. Results will contain the filtered items.

Usage:

```js
// Give the results from a model whose output has the name 'classification',
// filter for the top five probabilities above a threshold of 0.1

RNTensorIO.run({
  'image': {}
}, (error, results) =>  {
  classifications = results['classification'];

  RNTensorIO.topN(5, 0.1, classifications, (error, top5) => {
    console.log("TOP 5", top5);
  });
)};
```

### Constants

#### Image Input Keys

```js
RNTensorIO.imageKeyData
RNTensorIO.imageKeyFormat
RNTensorIO.imageKeyWidth
RNTensorIO.imageKeyHeight
RNTensorIO.imageKeyOrientation
```

##### RNTensorIO.imageKeyData

The data for the image. Must be a base64 encoded string or the fully qualified path to an image on the filesystem.

##### RNTensorIO.imageKeyFormat

The image format. See supported types below. Pixel buffer data coming directly from an iOS camera will usually have the format `RNTensorIO.imageOrientationRight`.

##### RNTensorIO.imageKeyWidth

The width of the underlying image. Only required if the format is `RNTensorIO.imageTypeARGB` or `RNTensorIO.imageTypeBGRA`. Pixel buffer data coming directly from an iOS device camera will often have a width of 640.

##### RNTensorIO.imageKeyHeight

The height of the underlying image. Only required if the format is `RNTensorIO.imageTypeARGB` or `RNTensorIO.imageTypeBGRA`. Pixel buffer data coming directly from an iOS device camera will often have a height of 480.

##### RNTensorIO.imageKeyOrientation

The orientation of the image. See supported formats below. Most images will be `RNTensorIO.imageOrientationUp`, and this is the default value that is used if this field is not specified. However, pixel buffer data coming directly from an iOS device camera will be `RNTensorIO.imageOrientationRight`.

#### Image Data Types

```js
RNTensorIO.imageTypeUnknown
RNTensorIO.imageTypeARGB
RNTensorIO.imageTypeBGRA
RNTensorIO.imageTypeJPEG
RNTensorIO.imageTypePNG
RNTensorIO.imageTypeFile
```

##### RNTensorIO.imageTypeUnknown

A placeholder for an unknown image type. RNTensorIO will return an error if you specify this format.

##### RNTensorIO.imageTypeARGB

Pixel buffer data whose pixels are unrolled into an alpha-red-green-blue byte representation.

##### RNTensorIO.imageTypeBGRA

Pixel buffer data whose pixels are unrolled into a blue-green-red-alpha byte representation. Pixel data coming directly from an iOS device camera will usually be in this format.

##### RNTensorIO.imageTypeJPEG

JPEG image data. The base64 encoded string must be prefixed with `data:image/jpeg;base64,`.

##### RNTensorIO.imageTypePNG

PNG image data. The base64 encoded string must be prefixed with `data:image/png;base64,`.

##### RNTensorIO.imageTypeFile

Indicates tha the image data will contain the fully qualified path to an image on the filesystem.

#### Image Orientations

```js
RNTensorIO.imageOrientationUp
RNTensorIO.imageOrientationUpMirrored
RNTensorIO.imageOrientationDown
RNTensorIO.imageOrientationDownMirrored
RNTensorIO.imageOrientationLeftMirrored
RNTensorIO.imageOrientationRight
RNTensorIO.imageOrientationRightMirrored
RNTensorIO.imageOrientationLeft
```

##### RNTensorIO.imageOrientationUp

0th row at top, 0th column on left. Default orientation.

##### RNTensorIO.imageOrientationUpMirrored

0th row at top, 0th column on right. Horizontal flip.

##### RNTensorIO.imageOrientationDown

0th row at bottom, 0th column on right. 180 degree rotation.

##### RNTensorIO.imageOrientationDownMirrored 

0th row at bottom, 0th column on left. Vertical flip.

##### RNTensorIO.imageOrientationLeftMirrored

0th row on left, 0th column at top.

##### RNTensorIO.imageOrientationRight

0th row on right, 0th column at top. 90 degree clockwise rotation. Pixel buffer data coming from an iOS device camera will usually have this orientation.

##### RNTensorIO.imageOrientationRightMirrored

0th row on right, 0th column on bottom.

##### RNTensorIO.imageOrientationLeft

0th row on left, 0th column at bottom. 90 degree counter-clockwise rotation.