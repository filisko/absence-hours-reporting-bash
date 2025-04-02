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

After installing it and running it for the first time, it will create a **JSON config file** where you will have to put your **Absence API ID and Key**.

To find API's credentials, you can go to: Absence ➜ Profile ➜ Integrations ➜ API Key (ID/Key).

Then, use the [last option](#show-last-time-entry) documented below to see how time entries are being created from your browser, so that you adjust the configuration file accordingly: timezone, timezone name and schedules.

Please be aware that these three settings might change overtime, e.g.: summer time change. Use the [last option](#show-last-time-entry) again to readjust the settings after you've created a time entry from the browser to use it as a reference.

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

### Show last time entry

You might be interested in what a time entry looks like, especially the last one.

We suggest you use this option to set up: the timezone, timezone name and schedules.

Usually what you would want to do is:
- Go to the browser.
- Create a time entry.
- See what it looks like with this operation.
- Adjust the config file accordingly (timezone, timezone name, start time, end time, etc.). This way you'll make sure that the time entries are created as the browser would.

```sh
absence.sh last
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
