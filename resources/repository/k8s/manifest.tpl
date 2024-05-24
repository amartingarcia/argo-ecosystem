---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: simple-server
  template:
    metadata:
      labels:
        app: simple-server
    spec:
      containers:
      - name: simple-server
        image: DOCKER_IMAGE:DOCKER_IMAGE_VERSION
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: simple-server
spec:
  selector:
    app: simple-server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
