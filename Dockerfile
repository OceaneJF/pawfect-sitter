#25 10.49 <s> [webpack.Progress] 92% sealing asset processing WebpackManifestPlugin
#25 10.51 <s> [webpack.Progress] 92% sealing asset processing
#25 10.51 <s> [webpack.Progress] 93% sealing after asset optimization
#25 10.51 <s> [webpack.Progress] 93% sealing after asset optimization
#25 10.51 <s> [webpack.Progress] 94% sealing after seal
#25 10.51 <s> [webpack.Progress] 94% sealing after seal
#25 10.51 <s> [webpack.Progress] 99% done plugins
#25 10.51 <s> [webpack.Progress] 99% done plugins clean-webpack-plugin
#25 10.51 <s> [webpack.Progress] 99% done plugins Notifier
#25 10.51 <s> [webpack.Progress] 99% done plugins FriendlyErrorsWebpackPlugin
#25 10.55  ERROR  Failed to compile with 1 errors10:42:52 PM
#25 10.55
#25 10.55 Module build failed: Module not found:
#25 10.55 "./assets/app.js" contains a reference to the file "@symfony/ux-vue".
#25 10.55 This file can not be found, please check it for typos or update it if the file got moved.
#25 10.55
#25 10.55 <s> [webpack.Progress] 99% done plugins
#25 10.55 <s> [webpack.Progress] 99%
#25 10.55
#25 10.55 <s> [webpack.Progress] 99% cache begin idle
#25 10.55 <s> [webpack.Progress] 99% cache begin idle
#25 10.55 <s> [webpack.Progress] 100%
#25 10.55
#25 10.55 <s> [webpack.Progress] 99% cache shutdown
#25 10.55 <s> [webpack.Progress] 99% cache shutdown
#25 10.55 <s> [webpack.Progress] 100%
#25 10.55
#25 10.56 Entrypoint app = runtime.8ab7f0c8.js 989.955cd3f5.js app.ab9b65e6.css app.3849d64b.js
#25 10.56 webpack compiled with 2 errors
#25 ERROR: process "/bin/sh -c npm run build &&     echo \"=== Checking build output ===\" &&     ls -la /app/public/build/ &&     ls -la /app/public/build/entrypoints.json &&     echo \"=== Build verification complete ===\"" did not complete successfully: exit code: 1
------
> [node_builder 11/11] RUN npm run build &&     echo "=== Checking build output ===" &&     ls -la /app/public/build/ &&     ls -la /app/public/build/entrypoints.json &&     echo "=== Build verification complete ===":
10.55 <s> [webpack.Progress] 99% cache begin idle
10.55 <s> [webpack.Progress] 99% cache begin idle
10.55 <s> [webpack.Progress] 100%
10.55
10.55 <s> [webpack.Progress] 99% cache shutdown
10.55 <s> [webpack.Progress] 99% cache shutdown
10.55 <s> [webpack.Progress] 100%
10.55
10.56 Entrypoint app = runtime.8ab7f0c8.js 989.955cd3f5.js app.ab9b65e6.css app.3849d64b.js
10.56 webpack compiled with 2 errors
------
Dockerfile:27
--------------------
|     # Build with verification
| >>> RUN npm run build && \
| >>>     echo "=== Checking build output ===" && \
| >>>     ls -la /app/public/build/ && \
| >>>     ls -la /app/public/build/entrypoints.json && \
| >>>     echo "=== Build verification complete ==="
|
--------------------
ERROR: failed to build: failed to solve: process "/bin/sh -c npm run build &&     echo \"=== Checking build output ===\" &&     ls -la /app/public/build/ &&     ls -la /app/public/build/entrypoints.json &&     echo \"=== Build verification complete ===\"" did not complete successfully: exit code: 1