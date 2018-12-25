:: set folder path
set dir_path=F:\
pushd %dir_path%
:: set min age of folders to delete
set max_days=1
REM forfiles/S /D -%max_days% /C "cmd /c IF @isdir == TRUE rd /S /Q @path"
forfiles /D -%max_days% /C "cmd /c IF @isdir == TRUE rd /S /Q @path"
popd
