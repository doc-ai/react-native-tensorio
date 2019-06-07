
import { NativeEventEmitter, NativeModules } from 'react-native';

export default NativeModules.RNTensorIO;

export const RNModelRepository = NativeModules.RNModelRepository;
export const RNFleaClient = NativeModules.RNFleaClient;
export const RNTensorIO = NativeModules.RNTensorIO;

export const RNFleaClientEventEmitter = new NativeEventEmitter(NativeModules.RNFleaClient);
export const RNModelRepositoryEventEmitter = new NativeEventEmitter(NativeModules.RNModelRepository);
