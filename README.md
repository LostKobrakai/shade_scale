# ShadeScale

- Deploy to fly with tigris bucket
- Make bucket public

```
flyctl storage update {{tigris-bucket-name}} -p
```

- Enable shadow bucket

```
flyctl storage update {{tigris-bucket-name}} \
    --shadow-access-key {{s3_access_key}} --shadow-secret-key {{s3_secret_key}} \
    --shadow-endpoint https://fly.dev/ --shadow-region auto \
    --shadow-name {{your-s3-bucket}}
```
