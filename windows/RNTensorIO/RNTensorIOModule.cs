using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Tensor.IO.RNTensorIO
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNTensorIOModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNTensorIOModule"/>.
        /// </summary>
        internal RNTensorIOModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNTensorIO";
            }
        }
    }
}
