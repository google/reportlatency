
/**
 * @fileoverview option_functions.js is loaded as part of the
 *   options.html page, and implements saving and restoring the static
 *   and dynamically registered options into localStorage, where the
 *   main extension can access them.
 * @author dld@google.com (Drake Diedrich)
 *
 * Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

function saveCheckbox(option) {
  var checkbox = document.getElementById(option);
  var value = checkbox.checked;
  localStorage[option] = value;
}

function saveText(option) {
  var text = document.getElementById(option);
  var value = text.value;
  if (value != '') {
    localStorage[option] = value;
  } else {
    delete localStorage[option];
  }
}

function saveServices() {
  for (var id in serviceGroup) {
    saveCheckbox(id);
  }
}

function saveOptions() {
  saveText('report_to');
  saveCheckbox('default_as_org');
  saveServices();
  saveCheckbox('debug_mode');
  saveCheckbox('log_navigations');
  saveCheckbox('log_requests');

  var status = document.getElementById('status');
  status.innerHTML = 'Options Saved.';
  setTimeout(function() {
    status.innerHTML = '';
  }, 750);
}


function string_to_bool(val) {
  if (val == 'true') {
    return true;
  } else {
    return false;
  }
}

function restoreCheckbox(option) {
  var value = localStorage[option];
  var checkbox = document.getElementById(option);
  checkbox.checked = string_to_bool(value);
}

function restoreText(option) {
  if (option in localStorage) {
    value = localStorage[option];
    var text = document.getElementById(option);
    text.value = value;
  }
}

function restoreServices() {
  var service_groups = document.getElementById('service_groups');
  var html = '';
  for (var id in serviceGroup) {
    html = html + '\n' + id +
        '<input type="checkbox" id="' + id + '" name="' + id +
        '">' + '\n<br>\n\n' +
        serviceGroup[id].description + '\n<p>\n';
  }
  service_groups.innerHTML = html;

  for (var id in serviceGroup) {
    restoreCheckbox(id);
  }
}

function restoreDefaults() {
  for (var option in optionDefault) {
    var value = optionDefault[option];
    var option_text = document.getElementById('default_' + option);
    option_text.innerHTML = '[ defaults to ' + value + ' ]';
  }
}

function restoreOptions() {
  restoreServices();
  restoreDefaults();
  restoreText('report_to');
  restoreCheckbox('default_as_org');
  restoreCheckbox('debug_mode');
  restoreCheckbox('log_requests');
  restoreCheckbox('log_navigations');
}

document.querySelector('#save').addEventListener('click', saveOptions);

chrome.runtime.sendMessage({ rpc: "get_options" },
			   function(response) {
			     serviceGroup = response.serviceGroup;
			     restoreOptions();
			   });
