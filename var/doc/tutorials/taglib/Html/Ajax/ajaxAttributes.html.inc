<o2 docListItem class="optional">formParams      - the names of the input fields whose values you would like to submit</o2:docListItem>
<o2 docListItem class="optional">target          - the id of the html element where you would like to insert html</o2:docListItem>
<o2 docListItem class="optional">where [replace] - where in the target element to insert the html displayed by the Gui module method. Possible values: replace, bottom, top, delete</o2:docListItem>
<o2 docListItem class="optional">onSuccess       - javascript code to execute on success.</o2:docListItem>
<o2 docListItem class="optional">onError         - javascript code to execute on error. By default the error message from the Gui module method is alerted. If onError="ignore",
                                 this error message is not alerted.</o2:docListItem>
<o2 docListItem class="optional">handler         - name of a javascript function to be called when the ajax call returns successfully</o2:docListItem>
<o2 docListItem class="optional">confirmMsg      - A message to display if the user needs to confirm the action he's about to perform</o2:docListItem>
<o2 docListItem class="optional">debug [0]</o2:docListItem>
<o2 docListItem class="optional">serverScript    - if UrlMod parameters don't work, you may use this instead</o2:docListItem>
<o2 docListItem class="optional">method [get]    - which request method to use for the AJAX request. One of {get, post}. Request that are longer than 2048 characters will always use the "post" request method.</o2:docListItem>
<o2 docListItem class="required">UrlMod parameters to specify the module and method to be called, and parameters (if any)</o2:docListItem>
