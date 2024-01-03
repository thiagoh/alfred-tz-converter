## Alfred Timezone Converter

### Develop

#### Building with ditto
```shell
ditto -ck . ~/Downloads/alfred-tz-converter-v1.0.8.alfredworkflow
```

#### Updating the bundle for testing

```shell
f=alfred-tz-converter.alfredworkflow && rm $f ; ditto -ck . $f && open $f
```
