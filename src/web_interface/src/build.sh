out_folder = "assets";

npm run build

mv out_folder/*.js ../../server/static/js
mv out_folder/*.css ../../server/static/css
rm -r out_folder
