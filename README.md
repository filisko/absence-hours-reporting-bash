# Absence.IO hours reporting tool

![ci](https://github.com/filisko/absence-hours-reporting-bash/actions/workflows/main.yml/badge.svg)

Fully tested Bash tool to register your breaks and working hours in absence.io.

## Setup

It requires the following binaries installed in your system (this is checked by the tool):
- jq
- curl
- openssl
- base64
- date

You probably already have openssl, base64 and date, to install the missing ones you can copy/paste:

<details>
<summary>Mac OS</summary>
  
```sh
brew install jq curl
```

</details>

<details>
<summary>Ubuntu</summary>
  
```sh
sudo apt-get install -y jq curl
```

</details>

## Installation

```sh
wget https://raw.githubusercontent.com/filisko/absence-hours-reporting-bash/refs/heads/main/src/absence.sh
chmod +x absence.sh
```

After installing it an running it for the first time, it will create a **JSON config file** where you have to put your **Absence API ID and Key, and configure your day schedule**.

To find API's credentials, you can go to: Absence -> Profile -> Integrations -> API Key (ID/Key).

## Usage

There are 3 possible options to use the tool:

### Register your hours for the day

It won't work on weekends as you probably don't want to register hours for the weekend).

```sh
absence.sh
```

### Register the hours for the whole week

Future hours registrations are not possible (Absence doesn't allow it) so it's suggested that you run it by the end of the week, Friday after finishing your working hours or the weekend.

If you run it any day before Friday it will register the hours for the previous days (e.g.: if you run it on a Wednesday, hours are registered for Monday, Tuestay and Wednesday).

Also, if you've registered your hours already for say, Tuesday, it will only throw an error for that day but that's it (there's no mechanism in the tool to check if the hours were already registered in Absence). 

```sh
absence.sh week
```

### Register a date range

This option allows you to specify your own date range. Similar to the previous option, future hours registrations are not possible.

```sh
absence.sh 2025-03-10 2025-03-13
```
