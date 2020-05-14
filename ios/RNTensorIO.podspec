
Pod::Spec.new do |s|
  s.name        = 'RNTensorIO'
  s.version     = '0.4.0'
  s.summary     = 'Machine Learning for React Native with TensorIO'
  s.description = 'Perform inference with TensorFlow Lite mondels in React Native'
  s.homepage    = 'https://github.com/doc-ai/react-native-tensorio'
  s.license     = { :type => 'Apache 2', :file => 'LICENSE' }
  s.authors     = { 'doc.ai' => 'philip@doc.ai' }
  s.source      = { :git => 'https://github.com/doc-ai/react-native-tensorio.git', :tag => s.version.to_s }
  
  s.ios.deployment_target   = '12.0'
  s.source_files            = '*.{h,m,mm}'
  s.requires_arc            = true
  s.static_framework        = true

  s.dependency 'React'
  s.dependency 'TensorIO'
  s.dependency 'TensorIO/TensorFlow'
end
