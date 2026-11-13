FROM nvcr.io/nvidia/pytorch:25.12-py3

COPY docker/requirements.txt /tmp/hvx-requirements.txt
RUN python3 -m pip install --no-cache-dir -r /tmp/hvx-requirements.txt

WORKDIR /workspace/Hvx

