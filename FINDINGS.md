## How to Run

```bash
./setup.sh
kubectl port-forward -n demo svc/demo-demo-service 8080:80 &
curl http://localhost:8080
```

Expected response:
```json
{"app":"demo-service","version":"1.0.0","pod":"demo-demo-service-..."}
```

## Project Structure

