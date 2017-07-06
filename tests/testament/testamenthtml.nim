import strutils

proc htmlQuote*(raw: string): string =
  if (raw.isNil):
    return nil
  result = raw
  result = result.replace("&", "&amp;")
  result = result.replace("\"", "&quot;")
  result = result.replace("'", "&apos;")
  result = result.replace("<", "&lt;")
  result = result.replace(">", "&gt;")

const
  html_begin_1* = """
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Testament Test Results</title>""" 
  html_begin_2* = """
    <script>
        /**
        * Callback function that is executed for each Element in an array.
        * @callback executeForElement
        * @param {Element} elem Element to operate on
        */

        /**
        * 
        * @param {number} index
        * @param {Element[]} elemArray
        * @param {executeForElement} executeOnItem
        */
        function executeAllAsync(elemArray, index, executeOnItem) {
            for (var i = 0; index < elemArray.length && i < 100; i++ , index++) {
                var item = elemArray[index];
                executeOnItem(item);
            }
            if (index < elemArray.length) {
                setTimeout(executeAllAsync, 0, elemArray, index, executeOnItem);
            }
        }

        /** @param {Element} elem */
        function executeShowOnElement(elem) {
            while (elem.classList.contains("hidden")) {
                elem.classList.remove("hidden");
            }
        }

        /** @param {Element} elem */
        function executeHideOnElement(elem) {
            if (!elem.classList.contains("hidden")) {
                elem.classList.add("hidden");
            }
        }

        /** @param {Element} elem */
        function executeExpandOnElement(elem) {
            if (!elem.classList.contains("in")) {
                elem.classList.add("in");
            }
        }

        /** @param {Element} elem */
        function executeCollapseOnElement(elem) {
            while (elem.classList.contains("in")) {
                elem.classList.remove("in");
            }
        }

        /**
        * @param {string} tabId The id of the tabpanel div to search.
        * @param {string} [category] Optional bootstrap panel context class (danger, warning, info, success)
        * @param {executeForElement} executeOnEachPanel
        */
        function wholePanelAll(tabId, category, executeOnEachPanel) {
            var selector = "div.panel";
            if (typeof category === "string" && category) {
                selector += "-" + category;
            }

            var jqPanels = $(selector, $("#" + tabId));
            /** @type {Element[]} */
            var elemArray = jqPanels.toArray();

            setTimeout(executeAllAsync, 0, elemArray, 0, executeOnEachPanel);
        }

        /**
        * @param {string} tabId The id of the tabpanel div to search.
        * @param {string} [category] Optional bootstrap panel context class (danger, warning, info, success)
        * @param {executeForElement} executeOnEachPanel
        */
        function panelBodyAll(tabId, category, executeOnEachPanelBody) {
            var selector = "div.panel";
            if (typeof category === "string" && category) {
                selector += "-" + category;
            }

            var jqPanels = $(selector, $("#" + tabId));

            var jqPanelBodies = $("div.panel-body", jqPanels);
            /** @type {Element[]} */
            var elemArray = jqPanelBodies.toArray();

            setTimeout(executeAllAsync, 0, elemArray, 0, executeOnEachPanelBody);
        }

        /**
        * @param {string} tabId The id of the tabpanel div to search.
        * @param {string} [category] Optional bootstrap panel context class (danger, warning, info, success)
        */
        function showAll(tabId, category) {
            wholePanelAll(tabId, category, executeShowOnElement);
        }

        /**
        * @param {string} tabId The id of the tabpanel div to search.
        * @param {string} [category] Optional bootstrap panel context class (danger, warning, info, success)
        */
        function hideAll(tabId, category) {
            wholePanelAll(tabId, category, executeHideOnElement);
        }

        /**
        * @param {string} tabId The id of the tabpanel div to search.
        * @param {string} [category] Optional bootstrap panel context class (danger, warning, info, success)
        */
        function expandAll(tabId, category) {
            panelBodyAll(tabId, category, executeExpandOnElement);
        }

        /**
        * @param {string} tabId The id of the tabpanel div to search.
        * @param {string} [category] Optional bootstrap panel context class (danger, warning, info, success)
        */
        function collapseAll(tabId, category) {
            panelBodyAll(tabId, category, executeCollapseOnElement);
        }
    </script>
</head>
<body>
    <div class="container">
        <h1>Testament Test Results <small>Nim Tester</small></h1>"""
  html_tablist_begin* = """
        <ul class="nav nav-tabs" role="tablist">"""
  html_tablistitem_format* = """
            <li role="presentation" class="$firstTabActiveClass">
                <a href="#tab-commit-$commitId-machine-$machineId" aria-controls="tab-commit-$commitId-machine-$machineId" role="tab" data-toggle="tab">
                    $branch#$hash@$machineName
                </a>
            </li>"""
  html_tablist_end* = """
        </ul>"""
  html_tabcontents_begin* = """
        <div class="tab-content">"""
  html_tabpage_begin_format* = """
            <div id="tab-commit-$commitId-machine-$machineId" class="tab-pane fade$firstTabActiveClass" role="tabpanel">
                <h2>$branch#$hash@$machineName</h2>
                <dl class="dl-horizontal">
                    <dt>Branch</dt>
                    <dd>$branch</dd>
                    <dt>Commit Hash</dt>
                    <dd><code>$hash</code></dd>
                    <dt>Machine Name</dt>
                    <dd>$machineName</dd>
                    <dt>OS</dt>
                    <dd>$os</dd>
                    <dt title="CPU Architecture">CPU</dt>
                    <dd>$cpu</dd>
                    <dt>All Tests</dt>
                    <dd>
                        <span class="glyphicon glyphicon-th-list"></span>
                        $totalCount
                    </dd>
                    <dt>Successful Tests</dt>
                    <dd>
                        <span class="glyphicon glyphicon-ok-sign"></span>
                        $successCount ($successPercentage)
                    </dd>
                    <dt>Skipped Tests</dt>
                    <dd>
                        <span class="glyphicon glyphicon-question-sign"></span>
                        $ignoredCount ($ignoredPercentage)
                    </dd>
                    <dt>Failed Tests</dt>
                    <dd>
                        <span class="glyphicon glyphicon-exclamation-sign"></span>
                        $failedCount ($failedPercentage)
                    </dd>
                </dl>
                <div class="table-responsive">
                    <table class="table table-condensed">
                        <tr>
                            <th class="text-right" style="vertical-align:middle">All Tests</th>
                            <td>
                                <div class="btn-group">
                                    <button class="btn btn-default" type="button" onclick="showAll('tab-commit-$commitId-machine-$machineId');">Show All</button>
                                    <button class="btn btn-default" type="button" onclick="hideAll('tab-commit-$commitId-machine-$machineId');">Hide All</button>
                                    <button class="btn btn-default" type="button" onclick="expandAll('tab-commit-$commitId-machine-$machineId');">Expand All</button>
                                    <button class="btn btn-default" type="button" onclick="collapseAll('tab-commit-$commitId-machine-$machineId');">Collapse All</button>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <th class="text-right" style="vertical-align:middle">Successful Tests</th>
                            <td>
                                <div class="btn-group">
                                    <button class="btn btn-default" type="button" onclick="showAll('tab-commit-$commitId-machine-$machineId', 'success');">Show All</button>
                                    <button class="btn btn-default" type="button" onclick="hideAll('tab-commit-$commitId-machine-$machineId', 'success');">Hide All</button>
                                    <button class="btn btn-default" type="button" onclick="expandAll('tab-commit-$commitId-machine-$machineId', 'success');">Expand All</button>
                                    <button class="btn btn-default" type="button" onclick="collapseAll('tab-commit-$commitId-machine-$machineId', 'success');">Collapse All</button>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <th class="text-right" style="vertical-align:middle">Skipped Tests</th>
                            <td>
                                <div class="btn-group">
                                    <button class="btn btn-default" type="button" onclick="showAll('tab-commit-$commitId-machine-$machineId', 'info');">Show All</button>
                                    <button class="btn btn-default" type="button" onclick="hideAll('tab-commit-$commitId-machine-$machineId', 'info');">Hide All</button>
                                    <button class="btn btn-default" type="button" onclick="expandAll('tab-commit-$commitId-machine-$machineId', 'info');">Expand All</button>
                                    <button class="btn btn-default" type="button" onclick="collapseAll('tab-commit-$commitId-machine-$machineId', 'info');">Collapse All</button>
                                </div>
                            </td>
                        </tr>
                        <tr>
                            <th class="text-right" style="vertical-align:middle">Failed Tests</th>
                            <td>
                                <div class="btn-group">
                                    <button class="btn btn-default" type="button" onclick="showAll('tab-commit-$commitId-machine-$machineId', 'danger');">Show All</button>
                                    <button class="btn btn-default" type="button" onclick="hideAll('tab-commit-$commitId-machine-$machineId', 'danger');">Hide All</button>
                                    <button class="btn btn-default" type="button" onclick="expandAll('tab-commit-$commitId-machine-$machineId', 'danger');">Expand All</button>
                                    <button class="btn btn-default" type="button" onclick="collapseAll('tab-commit-$commitId-machine-$machineId', 'danger');">Collapse All</button>
                                </div>
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="panel-group">"""
  html_testresult_panel_format* = """
                    <div id="panel-testResult-$trId" class="panel panel-$panelCtxClass">
                        <div class="panel-heading" style="cursor:pointer" data-toggle="collapse" data-target="#panel-body-testResult-$trId" aria-controls="panel-body-testResult-$trId" aria-expanded="false">
                            <div class="row">
                                <h4 class="col-xs-3 col-sm-1 panel-title">
                                    <span class="glyphicon glyphicon-$resultSign-sign"></span>
                                    <strong>$resultDescription</strong>
                                </h4>
                                <h4 class="col-xs-1 panel-title"><span class="badge">$target</span></h4>
                                <h4 class="col-xs-5 col-sm-7 panel-title" title="$name"><code class="text-$textCtxClass">$name</code></h4>
                                <h4 class="col-xs-3 col-sm-3 panel-title text-right"><span class="badge">$category</span></h4>
                            </div>
                        </div>
                        <div id="panel-body-testResult-$trId" class="panel-body collapse bg-$bgCtxClass">
                            <dl class="dl-horizontal">
                                <dt>Name</dt>
                                <dd><code class="text-$textCtxClass">$name</code></dd>
                                <dt>Category</dt>
                                <dd><span class="badge">$category</span></dd>
                                <dt>Timestamp</dt>
                                <dd>$timestamp</dd>
                                <dt>Nim Action</dt>
                                <dd><code class="text-$textCtxClass">$action</code></dd>
                                <dt>Nim Backend Target</dt>
                                <dd><span class="badge">$target</span></dd>
                                <dt>Code</dt>
                                <dd><code class="text-$textCtxClass">$result</code></dd>
                            </dl>
                            $outputDetails
                        </div>
                    </div>"""
  html_testresult_output_format* = """
                            <div class="table-responsive">
                                <table class="table table-condensed">
                                    <thead>
                                        <tr>
                                            <th>Expected</th>
                                            <th>Actual</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td><pre>$expected</pre></td>
                                            <td><pre>$gotten</pre></td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>"""
  html_testresult_no_output* = """
                            <p class="sr-only">No output details</p>"""
  html_tabpage_end* = """
                </div>
            </div>"""
  html_tabcontents_end* = """
        </div>"""
  html_end* = """
    </div>
</body>
</html>"""