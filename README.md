<h1 align="center">
  <img src="/.github/logo.png"/>
</h1>

Woofed CRM is a Open source CRM Software.

🚧 **Under development** 🚧

## Layout

![Woofed CRM](/.github/layout.png)

## Let's try

You can try the development version through the link:
https://woofed-crm-development.herokuapp.com

## Setup development environment

Requeriments for project:
```
python 2.7.13
ruby 3.0.0
nodejs 16.16.0
```
### 1 - Clone repository
```sh
git clone https://github.com/douglara/woofed-crm.git
cd woofed-crm
```
### 2 - Install dependencies

```sh
bundle install
yarn build
```
### 3 - Create .env file

Create .env file

```sh
cp .env.sample .env
```

### 4 - Up containers

```sh
docker-compose up -d
```

### 5 - Configure database

```sh
rails db:create
rails db:migrate
rails db:seed
```

### 6 - Start applications

```sh
./bin/dev
```

Access `http://127.0.0.1:3001` and use user `user1@email.com` password: `123456`

## Contributing

This project is intended to be a safe, welcoming space for collaboration.
