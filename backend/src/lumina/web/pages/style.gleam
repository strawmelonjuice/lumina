import birl

import gleam/int

import gleam/string

import lumina/data/context.{type Context}
import simplifile as fs

/// Merges tailwind artifacts, custom CSS, and special event CSS into a single stylesheet
pub fn sheet(ctx: Context) {
  "\n\n\n/* --- Main stylesheet --- */\n\n\n"
  <> case fs.read(from: ctx.priv_directory <> "/generated/css/main.min.css") {
    Ok(css) -> css
    Error(_) -> "// Error reading main stylesheet\n"
  }
  <> "\n\n\n/* --- Custom instance-specific CSS content --- */\n\n\n"
  <> case fs.read(from: ctx.config_dir <> "/custom-styles.css") {
    Ok(css) -> css
    Error(_) -> "// Error reading custom CSS\n"
  }
  <> "\n\n\n/* --- CSS content for special events --- */\n\n\n"
  <> string.replace(
    "

  /*Pride month banner*/
  body:has(.monthclass-6)::before {
      margin: 0;
      content: \"Happy Pride Month! 💖🏳️‍🌈\";
      justify-content: center;
      align-items: center;
      height: 1.4em;
      color: black;
      width: 100VW;
      border-radius: 0;
      display: inline-flex;
      background-image: linear-gradient(to right, rgb(237, 34, 36), rgb(243, 91, 34), rgb(249, 150, 33), rgb(245, 193, 30), rgb(241, 235, 27) 27%, rgb(241, 235, 27), rgb(241, 235, 27) 33%, rgb(99, 199, 32), rgb(12, 155, 73), rgb(33, 135, 141), rgb(57, 84, 165), rgb(97, 55, 155), rgb(147, 40, 142))
  }



  body:has(.monthclass-6) {
  --bs: 300% 100%;

  }
  body:has(.monthclass-6):hover::before {
  animation: prideBannerAnimation 10s linear infinite;
    }
  @keyframes prideBannerAnimation {
    0% {  }
    25% { background-position: 0 0;
      background-size: var(--bs);
    background-repeat: repeat;}
      30% { background-position: 50% 0;
          content: \"Protect LGBTQ+ Rights! 🏳️‍🌈✊\";
          background-size: var(--bs);
          background-repeat: repeat;
      }
    50% { background-position: 100% 0;
  content: \"Protect LGBTQ+ Rights! 🏳️‍🌈✊\";
      background-size: var(--bs);
    background-repeat: repeat;
    }

    75% { background-position: 0 0;
      background-size: var(--bs);
    background-repeat: repeat;
    }
      80% { background-position: 50% 0;
          content: \"Protect LGBTQ+ Rights!  🏳️‍🌈 ✊\";
          background-size: var(--bs);
          background-repeat: repeat;
      }
    100% {  }
  }
  body:has(.monthclass-6):active::before {
      animation: none;
      animation-delay: 3s;
      animation-duration: 999s;
      animation-name: transrights;
      animation-iteration-count: 1;
      animation-timing-function: ease-in-out;
  }
  @keyframes transrights {
      0% {
          content: \"Protect trans Rights!  ✊ 🩵🩷🤍🩷🩵\";
          background-image: linear-gradient(to right, rgb(85, 205, 252), rgb(179, 157, 233), rgb(247, 168, 184), rgb(246, 216, 221), rgb(255, 255, 255) 45%, rgb(255, 255, 255), rgb(255, 255, 255) 55%, rgb(246, 216, 221), rgb(247, 168, 184), rgb(179, 157, 233), rgb(85, 205, 252));
      }
  }
  /*29th of februari is nonexistent in non-leap years*/
  body:has(.dayclass-29.monthclass-2)::before {
      margin-top: .8em;
      margin-bottom: .8em;
      content: \"[This day does not exist]\";
      justify-content: center;
      align-items: center;
      height: 2.4em;
      flex: none;
      color: yellow;
      width: 100%;
      display: inline-flex;
      background-color: black;
      text-shadow: 22px 4px 2px rgba(255,255,0,0.6);
      box-shadow: 2px 2px 10px 8px #3d3a3a;
      animation-name: glitched;
      animation-duration: 3s;
      animation-iteration-count: infinite;
      animation-timing-function: linear;
      animation-direction: alternate;
  }
  @keyframes glitched {
      0% {
          transform: skew(-20deg);
          left: -4px;
      }
      10% {
          transform: skew(-20deg);
          left: -4px;
      }
      11% {
          transform: skew(0deg);
          left: 2px;
      }
      50% {
          transform: skew(0deg);
      }
      51% {
          transform: skew(10deg);
      }
      59% {
          transform: skew(10deg);
      }
      60% {
          transform: skew(0deg);
      }
      100% {
          transform: skew(0deg);
      }
  }
  ",
    "\n",
    "",
  )
  |> string.replace("  ", "")
  |> string.replace("\r", "")
}

pub fn monthclass() {
  "monthclass-"
  <> int.to_string(
    birl.get_day(birl.utc_now()).month,
    // Leaving this here as a reminder of the pain of not looking into the source first
  // case birl.month(birl.utc_now()) {
  //   birl.Jan -> 1
  //   birl.Feb -> 2
  //   birl.Mar -> 3
  //   birl.Apr -> 4
  //   birl.May -> 5
  //   birl.Jun -> 6
  //   birl.Jul -> 7
  //   birl.Aug -> 8
  //   birl.Sep -> 9
  //   birl.Oct -> 10
  //   birl.Nov -> 11
  //   birl.Dec -> 12
  // }
  )
}

pub fn dayclass() {
  "dayclass-" <> birl.get_day(birl.utc_now()).date |> int.to_string
}
