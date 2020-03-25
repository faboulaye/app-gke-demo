#! /bin/bash
apt-get update -y
apt-get install apache2 -y
cat <<EOF> /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Hello World</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css"
      integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
  </head>
  <body>
    <div class="jumbotron jumbotron-fullheight jumbo-vertical-center text-light text-center bg-info mb-0 radius-0">
      <div class="container">
          <h1 class="display-2 text-light">Hello World</h1>
      </div>
    </div>
    <blockquote class="blockquote text-center">
      <p class="mb-0">You are on the host <cite title="Source Title">$(hostname)</cite></p>
    </blockquote>
  </body>
</html>
EOF
