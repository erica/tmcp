# tmcp

Perform a time machine copy on flat files

```
Usage: tmcp paths
       tmcp --offset count paths
       tmcp --list (count)
       tmcp --help

Copies time machine versions to the current folder
appending the time machine date to the copy.
For example `tmcp --offset 3 README.txt` might
copy the file to `README.txt+2016-09-30-100004`
```


#### See also [tmdiff](https://github.com/erica/tmdiff), [tmls](https://github.com/erica/tmls)