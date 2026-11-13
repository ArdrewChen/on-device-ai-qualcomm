hvx_add_script_target(
  hvx_deploy_tiny_cnn_qnn_convert
  deploy/tiny_cnn/model/scripts/qnn-build.sh
)
hvx_add_script_target(
  hvx_deploy_tiny_cnn_qnn_context
  deploy/tiny_cnn/model/scripts/qnn-context.sh
)
hvx_add_script_target(
  hvx_deploy_tiny_cnn_qnn_bundle
  deploy/tiny_cnn/model/scripts/qnn-bundle.sh
)
hvx_add_script_target(
  hvx_deploy_tiny_cnn_dsp_build
  deploy/tiny_cnn/operator/scripts/dsp-smoke-build.sh
)
hvx_add_script_target(
  hvx_deploy_tiny_cnn_dsp_run
  deploy/tiny_cnn/operator/scripts/dsp-smoke-run.sh
)
hvx_add_script_target(
  hvx_deploy_tiny_cnn
  deploy/tiny_cnn/scripts/deploy.sh
)

add_custom_target(hvx_pipeline_tiny_cnn
  COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target hvx_nn_tiny_cnn_distill
  COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target hvx_nn_tiny_cnn_inspect
  COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target hvx_deploy_tiny_cnn_qnn_convert
  COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target hvx_deploy_tiny_cnn_qnn_context
  COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target hvx_deploy_tiny_cnn_qnn_bundle
  COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target hvx_deploy_tiny_cnn
  COMMENT "Running tiny_cnn NN-to-deploy pipeline"
  USES_TERMINAL
  VERBATIM
)

