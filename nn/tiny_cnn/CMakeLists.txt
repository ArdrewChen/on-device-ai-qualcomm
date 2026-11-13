hvx_add_script_target(
  hvx_nn_tiny_cnn_distill
  nn/tiny_cnn/scripts/distill.sh
  DEPENDS hvx_runtime_image
)
hvx_add_script_target(
  hvx_nn_tiny_cnn_calibration
  nn/tiny_cnn/scripts/calibration.sh
  DEPENDS hvx_runtime_image
)
hvx_add_script_target(
  hvx_nn_tiny_cnn_inspect
  nn/tiny_cnn/scripts/inspect.sh
  DEPENDS hvx_runtime_image
)
hvx_add_script_target(
  hvx_nn_tiny_cnn_test
  nn/tiny_cnn/scripts/test.sh
  DEPENDS hvx_runtime_image
)

