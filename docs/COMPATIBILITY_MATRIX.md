# Compatibility Matrix

| Module Version / Kubernetes Version |       1.20.X       |       1.21.X       |       1.22.X       | 1.23.X             | 1.24.X             | 1.25.X             | 1.26.X             | 1.27.X             | 1.28.X             | 1.29.X             | 1.30.X             | 1.31.X             | 1.32.X             |
| ----------------------------------- | :----------------: | :----------------: | :----------------: | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ | ------------------ |
| v0.0.1                              | :white_check_mark: |     :warning:      |        :x:         | :x:                | :x:                |                    |                    |                    |                    |                    |                    |                    |                    |
| v0.0.2                              |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    |                    |                    |                    |                    |                    |                    |
| v0.0.3                              |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    |                    |                    |                    |                    |                    |
| v0.0.4                              |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    |                    |                    |                    |                    |
| v0.1.0                              |                    |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |                    |                    |                    |                    |
| v0.2.0                              |                    |                    |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |
| v0.3.0                              |                    |                    |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |
| v0.4.0                              |                    |                    |                    |                    |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |                    |
| v0.5.0                              |                    |                    |                    |                    |                    |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| v0.5.1                              |                    |                    |                    |                    |                    |                    |                    |                    |                    | :white_check_mark: | :white_check_mark: | :white_check_mark: | :white_check_mark: |

:white_check_mark: Compatible

:warning: Has issues

:x: Incompatible

## Warnings

- Provided version of `Dex` in v0.0.1 is not compatible with Kubernets 1.21 out of the box. It needs a patch with the pod's namespace as an environment variable.
