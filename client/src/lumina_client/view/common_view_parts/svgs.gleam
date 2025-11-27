//// Lumina > Client > View > Application/Homepage > Common View Parts > SVGs
//// This module contains reusable SVG components used throughout the Lumina client.

//	Lumina/Peonies
//	Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as published
//	by the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.

import lustre/attribute.{attribute, class}
import lustre/element/svg

/// Globe SVG icon used in various parts of the Lumina client.
///
/// Thank <https://www.svgrepo.com/svg/524520/earth> for this, otherwise we'd have been stuck with my older design.
pub fn globe(classes: String) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      class(classes),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.circle([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute("r", "10"),
        attribute("cy", "12"),
        attribute("cx", "12"),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M6 4.71053C6.78024 5.42105 8.38755 7.36316 8.57481 9.44737C8.74984 11.3955 10.0357 12.9786 12 13C12.7549 13.0082 13.5183 12.4629 13.5164 11.708C13.5158 11.4745 13.4773 11.2358 13.417 11.0163C13.3331 10.7108 13.3257 10.3595 13.5 10C14.1099 8.74254 15.3094 8.40477 16.2599 7.72186C16.6814 7.41898 17.0659 7.09947 17.2355 6.84211C17.7037 6.13158 18.1718 4.71053 17.9377 4",
        ),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M22 13C21.6706 13.931 21.4375 16.375 17.7182 16.4138C17.7182 16.4138 14.4246 16.4138 13.4365 18.2759C12.646 19.7655 13.1071 21.3793 13.4365 22",
        ),
      ]),
    ],
  )
}

/// Two people overlapping
/// This one is by me :) - Strawmelonjuice
pub fn follows(classes: String) {
  svg.svg(
    [
      attribute.class(classes),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.circle([
        attribute.attribute("cx", "8"),
        attribute.attribute("cy", "8"),
        attribute.attribute("r", "3"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-width", "2"),
      ]),
      svg.circle([
        attribute.attribute("cx", "16"),
        attribute.attribute("cy", "8"),
        attribute.attribute("r", "3"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-width", "2"),
      ]),
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute("d", "M2 20v-1a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v1"),
      ]),
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute("d", "M14 20v-1a4 4 0 0 1 4-4h0a4 4 0 0 1 4 4v1"),
      ]),
    ],
  )
}

/// Heart and star overlapping for 'mutuals'
/// Also by me :) - Strawmelonjuice
pub fn mutuals(classes: String) {
  svg.svg(
    [
      attribute.class(classes),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      // Heart shape, offset to the left, with classic 'v' top and reduced opacity
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute(
          "d",
          "M9 19C5 15 2 12.5 2 9.5C2 7 4 5 6.5 5C8 5 9 6.5 9 6.5C9 6.5 10 5 11.5 5C14 5 16 7 16 9.5C16 12.5 13 15 9 19Z",
        ),
        attribute.attribute("opacity", "0.6"),
      ]),
      // Star shape, offset to the right and overlapping, with reduced opacity
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute(
          "d",
          "M15 4.5l2.09 4.24 4.68.68-3.39 3.3.8 4.63L15 15.77l-4.18 2.18.8-4.63-3.39-3.3 4.68-.68L15 4.5z",
        ),
        attribute.attribute("opacity", "0.6"),
      ]),
    ],
  )
}

/// Pen, for editing text posts, also called 'jot mode'.
///
/// Also from svgrepo: https://www.svgrepo.com/svg/524793/pen-2
pub fn pen(classes: String) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      class(classes),
    ],
    [
      svg.path([
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute("d", "M4 22H20"),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M13.8881 3.66293L14.6296 2.92142C15.8581 1.69286 17.85 1.69286 19.0786 2.92142C20.3071 4.14999 20.3071 6.14188 19.0786 7.37044L18.3371 8.11195M13.8881 3.66293C13.8881 3.66293 13.9807 5.23862 15.3711 6.62894C16.7614 8.01926 18.3371 8.11195 18.3371 8.11195M13.8881 3.66293L7.07106 10.4799C6.60933 10.9416 6.37846 11.1725 6.17992 11.4271C5.94571 11.7273 5.74491 12.0522 5.58107 12.396C5.44219 12.6874 5.33894 12.9972 5.13245 13.6167L4.25745 16.2417M18.3371 8.11195L11.5201 14.9289C11.0584 15.3907 10.8275 15.6215 10.5729 15.8201C10.2727 16.0543 9.94775 16.2551 9.60398 16.4189C9.31256 16.5578 9.00282 16.6611 8.38334 16.8675L5.75834 17.7426M5.75834 17.7426L5.11667 17.9564C4.81182 18.0581 4.47573 17.9787 4.2485 17.7515C4.02128 17.5243 3.94194 17.1882 4.04356 16.8833L4.25745 16.2417M5.75834 17.7426L4.25745 16.2417",
        ),
      ]),
    ],
  )
}

/// Camera icon for 'media' posts.
///
/// https://www.svgrepo.com/svg/524361/camera
pub fn camera(classes: String) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      class(classes),
    ],
    [
      svg.circle([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute("r", "3"),
        attribute("cy", "13"),
        attribute("cx", "12"),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M9.77778 21H14.2222C17.3433 21 18.9038 21 20.0248 20.2646C20.51 19.9462 20.9267 19.5371 21.251 19.0607C22 17.9601 22 16.4279 22 13.3636C22 10.2994 22 8.76721 21.251 7.6666C20.9267 7.19014 20.51 6.78104 20.0248 6.46268C19.3044 5.99013 18.4027 5.82123 17.022 5.76086C16.3631 5.76086 15.7959 5.27068 15.6667 4.63636C15.4728 3.68489 14.6219 3 13.6337 3H10.3663C9.37805 3 8.52715 3.68489 8.33333 4.63636C8.20412 5.27068 7.63685 5.76086 6.978 5.76086C5.59733 5.82123 4.69555 5.99013 3.97524 6.46268C3.48995 6.78104 3.07328 7.19014 2.74902 7.6666C2 8.76721 2 10.2994 2 13.3636C2 16.4279 2 17.9601 2.74902 19.0607C3.07328 19.5371 3.48995 19.9462 3.97524 20.2646C5.09624 21 6.65675 21 9.77778 21Z",
        ),
      ]),
      svg.path([
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute("d", "M19 10H18"),
      ]),
    ],
  )
}

/// Pen and paper icon for 'article' posts.
///
/// From svgrepo: https://www.svgrepo.com/svg/524784/pen-paper
pub fn pen_paper(classes: String) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
      class(classes),
    ],
    [
      svg.path([
        attribute("stroke-linecap", "round"),
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M22 10.5V12C22 16.714 22 19.0711 20.5355 20.5355C19.0711 22 16.714 22 12 22C7.28595 22 4.92893 22 3.46447 20.5355C2 19.0711 2 16.714 2 12C2 7.28595 2 4.92893 3.46447 3.46447C4.92893 2 7.28595 2 12 2H13.5",
        ),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M16.652 3.45506L17.3009 2.80624C18.3759 1.73125 20.1188 1.73125 21.1938 2.80624C22.2687 3.88124 22.2687 5.62415 21.1938 6.69914L20.5449 7.34795M16.652 3.45506C16.652 3.45506 16.7331 4.83379 17.9497 6.05032C19.1662 7.26685 20.5449 7.34795 20.5449 7.34795M16.652 3.45506L10.6872 9.41993C10.2832 9.82394 10.0812 10.0259 9.90743 10.2487C9.70249 10.5114 9.52679 10.7957 9.38344 11.0965C9.26191 11.3515 9.17157 11.6225 8.99089 12.1646L8.41242 13.9M20.5449 7.34795L14.5801 13.3128C14.1761 13.7168 13.9741 13.9188 13.7513 14.0926C13.4886 14.2975 13.2043 14.4732 12.9035 14.6166C12.6485 14.7381 12.3775 14.8284 11.8354 15.0091L10.1 15.5876M10.1 15.5876L8.97709 15.9619C8.71035 16.0508 8.41626 15.9814 8.21744 15.7826C8.01862 15.5837 7.9492 15.2897 8.03811 15.0229L8.41242 13.9M10.1 15.5876L8.41242 13.9",
        ),
      ]),
    ],
  )
}
