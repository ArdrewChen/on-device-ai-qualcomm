hvx_add_script_target(hvx_runtime_image runtime/scripts/docker-build.sh)
hvx_add_script_target(
  hvx_runtime_shell
  runtime/scripts/docker-run.sh
  ARGS bash
  DEPENDS hvx_runtime_image
)
hvx_add_script_target(
  hvx_doctor
  runtime/scripts/doctor.sh
  DEPENDS hvx_runtime_image
)

