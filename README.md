# 📅 Absence.IO hours reporting tool

![ci](https://github.com/filisko/absence-hours-reporting-bash/actions/workflows/main.yaml/badge.svg)

A robust and thoroughly tested Bash script to automatically register your breaks and working hours in absence.io for Mac OS and GNU/Linux.

## 🔧 Setup

The tool requires the following binaries installed in your system (this is checked by the tool):
- jq
- curl
- openssl
- base64
- date

You may already have base64 and date, to install the missing ones you can copy/paste:

<details>
<summary>Mac OS</summary>
  
```sh
brew install jq curl openssl
```

</details>

<details>
<summary>Ubuntu</summary>
  
```sh
sudo apt-get install -y jq curl openssl
```

</details>

## ⚙️ Installation

```sh
wget https://raw.githubusercontent.com/filisko/absence-hours-reporting-bash/refs/heads/main/src/absence.sh
chmod +x absence.sh
```

After installing it an running it for the first time, it will create a **JSON config file** where you have to put your **Absence API ID and Key, and configure your day schedule**.

To find API's credentials, you can go to: Absence -> Profile -> Integrations -> API Key (ID/Key).

## 🕹️ Usage

There are 3 possible options to use the tool:

### Register your hours for current day

It won't work on weekends as you probably don't like to work and register hours on a weekend.

```sh
absence.sh
```

### Register the hours for the whole week

Future hours registrations are not possible (Absence doesn't allow it) so it's suggested that you run it by the end of the week, Friday after finishing your working hours or the weekend.

If you run it any day before Friday it will register the hours for the previous days (e.g.: if you run it on a Wednesday, hours are registered for Monday, Tuestay and Wednesday).

Also, if you've registered your hours already for some day, it will only throw an error for that day but it will continue processing the rest of the days (there's no mechanism in the tool to check if the hours were already registered in Absence). 

```sh
absence.sh week
```

### Register a date range

This option allows you to specify your own date range. Similar to the previous option, future hours registrations are not possible.

```sh
absence.sh 2025-03-10 2025-03-13
```

### Show help

Shows a short description of all the available options.

```sh
absence.sh help
```

## 🤝 Contributing

### Clone the project:

```sh
git clone git@github.com:filisko/absence-hours-reporting-bash.git
```

### Watch & Run the tests:

This watches for changes either on the code or any of the tests.

```sh
# watch all tests
./watch.sh tests

# watch one specific test (probably what you want first)
./watch.sh tests/run.test.sh
```

### Run all tests:

This script is used for GitHub actions. It runs all tests.

```sh
./tests.sh
```

## 🧾 License

This project is licensed under the MIT License (MIT). Please see [LICENSE](https://github.com/filisko/absence-hours-reporting-bash/blob/main/LICENSE)
 for more information.
