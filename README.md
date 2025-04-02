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

After installing it an running it for the first time, it will create a **JSON config file** where you have to put your **Absence API ID and Key, configure your day schedule and your time zone (please note that this might change throughout its usage, e.g.: summer time change)**.

To find API's credentials, you can go to: Absence -> Profile -> Integrations -> API Key (ID/Key).

## 🕹️ Usage

### Register your hours for current day

Restrictions:
- It won't allow you to submit the hours on weekends as you probably don't want that.
- Future dates are not possible (restricted by Absence).
- Days with registered Absences (sickness, vacation, etc.) are skipped (an error will popup).
- Days with Holidays are skipped (an error will popup).
- Days with already registered hours are skipped (an Absence API error will popup).

```sh
absence.sh
```

### Register your hours for the whole week

With the same restrictions as the previous one.

If you run it any day before Friday it will register the hours for the previous days (e.g.: if you run it on a Wednesday, hours are registered for Monday, Tuestay and Wednesday).

```sh
absence.sh week
```

### Register a date range

With the same restrictions as the previous one.

This option allows you to specify your own dates range.

```sh
absence.sh 2025-03-10 2025-03-13
```

### Show help

Shows a short description of all the available options.

```sh
absence.sh help
```

## 🚩 Known issues

tofill

## 🤝 Contributing

### Clone the project:

```sh
git clone git@github.com:filisko/absence-hours-reporting-bash.git
```

### Install BashUnit:

```sh
./install_bashunit.sh
```

### Watch & Run the tests:

This watches for changes either on the code or any of the tests.

```sh
# watch all tests
./watch.sh tests

# watch one specific test (probably what you want at first)
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
