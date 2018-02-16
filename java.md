### iterate file content
```
Path path = Paths.get("/some/file");
    // alternatives:
    // path = new File("/some/file").toPath();
    // path = FileSystems.getDefault().getPath("/some/file");

Files.lines(path).map(this::readLine);

```