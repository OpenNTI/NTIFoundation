/// Things that get injected into every page

var NextThought = NextThought || {};

//This global variable will be injected into the global object (window),
//in the desktop-ui mockup, we change this variable's value on each ajax call.
var documentURL = document.URL;

/**
*
*  Base64 encode / decode
*  http://www.webtoolkit.info/
*
**/

var Base64 = {

	// private property
	_keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

	// public method for encoding
	encode : function (input) {
		var output = "";
		var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
		var i = 0;

		input = Base64._utf8_encode(input);

		while (i < input.length) {

			chr1 = input.charCodeAt(i++);
			chr2 = input.charCodeAt(i++);
			chr3 = input.charCodeAt(i++);

			enc1 = chr1 >> 2;
			enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
			enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
			enc4 = chr3 & 63;

			if (isNaN(chr2)) {
				enc3 = enc4 = 64;
			} else if (isNaN(chr3)) {
				enc4 = 64;
			}

			output = output +
			this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
			this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

		}

		return output;
	},

	// private method for UTF-8 encoding
	_utf8_encode : function (string) {
		string = string.replace(/\r\n/g,"\n");
		var utftext = "";

		for (var n = 0; n < string.length; n++) {

			var c = string.charCodeAt(n);

			if (c < 128) {
				utftext += String.fromCharCode(c);
			}
			else if((c > 127) && (c < 2048)) {
				utftext += String.fromCharCode((c >> 6) | 192);
				utftext += String.fromCharCode((c & 63) | 128);
			}
			else {
				utftext += String.fromCharCode((c >> 12) | 224);
				utftext += String.fromCharCode(((c >> 6) & 63) | 128);
				utftext += String.fromCharCode((c & 63) | 128);
			}

		}

		return utftext;
	}
};

var NTILastSelectionAnchor = null;

function NTIInlineNoteSaveSelection()
{
	NTILastSelectionAnchor = document.getSelection().anchorNode;
}

/**
 * @return The given note, set with a hidden class and otherwise styled.
 */

function NTIInlineNoteCreateDomElement( note )
{
	var noteDiv = document.createElement('div');
	NTIInlineNoteApplyStyle( noteDiv );
	noteDiv.id = note.id;
	noteDiv.innerHTML = note.text
	return noteDiv;
}

function NTIInlineNoteApplyStyle( newChild )
{
	newChild.className = 'inlinenote';
	return newChild;
}

function NTIInlineNoteByID(id)
{
	return  $('#'+id)[0]
}

function NTIInlineNoteReplyToNote(note, inReplyToID){
	var inReplyTo = NTIInlineNoteByID(inReplyToID);
	inReplyTo.appendChild(NTIInlineNoteCreateDomElement(note));
}

function NTIInlineNoteCreateThreadAsChild(parent, thread)
{
	var threadRoot = NTIInlineNoteCreateDomElement(thread.root);

	parent.appendChild(threadRoot)

	if(thread.children){
		for (var i=0; i<thread.children.length; i++){
			NTIInlineNoteCreateThreadAsChild(threadRoot, thread.children[i]);
		}
	}
}

function NTIInlineNoteCreateThreadInReplyToID(inReplyToID, thread)
{
	var inReplyTo = NTIInlineNoteByID(inReplyToID);

	return NTIInlineNoteCreateThreadAsChild(inReplyTo, thread);
}

function NTIInlineNoteMakeThreadFromSelectionOrAt(thread, x, y)
{
	//If there is a selection, use that because the
	//x and y are horible, they don't convert well
	var parent = null;
	var doBefore = false;
	var selection = document.getSelection();
	var anchorNode = selection.anchorNode;
	if( !anchorNode ) {
		anchorNode = NTILastSelectionAnchor;
	}
	NTILastSelectionAnchor = null;
	if( anchorNode ) {
		parent = anchorNode.parentElement;
		if( parent && $(parent).hasClass( "page-contents" ) ) {
			//Hmm. OK. We found the root element, not the one we were looking for.
			//In the past, some pages failed to have proper paragraph
			//structure so this was common. It should be
			//much less common now.
			if( anchorNode.nodeType == Node.TEXT_NODE ) {
				//So instead we'll put it here.
				parent = anchorNode;
				doBefore = true;
			}
		}
	}
	var log = "";
	if( !parent ) {
		parent = document.elementFromPoint(x,y);
		log += "Got parent from point";
	}
	if( !parent ) {
		return null;
	}

	var threadednote = document.createElement( "div" );
	threadednote.className = 'threadednote';

	NTIInlineNoteCreateThreadAsChild(threadednote, thread);

	if( doBefore ) {
		log += " doBefore; ";
		if( parent.nextSibling ) {
			log += " nextSibling; ";
			parent.parentElement.insertBefore( threadednote, parent.nextSibling );
		}
		else {
			parent.parentElement.insertBefore( threadednote, parent );
		}
	}
	else {
		log += " do direct; ";
		parent.appendChild( threadednote );
	}

	window.setTimeout( function() { $(threadednote).removeClass( 'hidden' ); },
					   100 );

	//Find the nearest anchor point
	var anchorPoint = null, anchorType = null;
	console.log( parent );
	if( parent['id'] ) {
		anchorPoint = parent['id'];
		anchorType = 'id';
	}
	// TODO: This does not handle encountering a text node.
	else if( parent.previousSibling && parent.previousSibling['name'] ) {
		anchorPoint = parent.previousSibling['name'];
		anchorType = 'previousName';
	}
	//Try to go one further up
	else if( parent.previousSibling && parent.previousSibling.previousSibling && parent.previousSibling.previousSibling['name'] ) {
		anchorPoint = parent.previousSibling.previousSibling['name'];
		anchorType = 'previousPreviousName';
	}
	else {
		log += " up three, no anchor; ";
		if( parent.previousSibling ) { log += "; prevSib: " + parent.previousSibling; }
		if( parent.previousSibling.previousSibling ) { log += "; prevSib: " + parent.previousSibling.previousSibling; }
	}
	return JSON.stringify( [anchorPoint, anchorType, log] );

}

/**
 * @return The JSON string for a two element array of
 * anchor point and anchor type.
 */
function NTIInlineNoteMakeFromSelectionOrAt( note, x, y )
{
	//If there is a selection, use that because the
	//x and y are horible, they don't convert well
	var parent = null;
	var doBefore = false;
	var selection = document.getSelection();
	var anchorNode = selection.anchorNode;
	if( !anchorNode ) {
		anchorNode = NTILastSelectionAnchor;
	}
	NTILastSelectionAnchor = null;
	if( anchorNode ) {
		parent = anchorNode.parentElement;
		if( parent && $(parent).hasClass( "page-contents" ) ) {
			//Hmm. OK. We found the root element, not the one we were looking for.
			//In the past, some pages failed to have proper paragraph
			//structure so this was common. It should be
			//much less common now.
			if( anchorNode.nodeType == Node.TEXT_NODE ) {
				//So instead we'll put it here.
				parent = anchorNode;
				doBefore = true;
			}
		}
	}
	var log = "";
	if( !parent ) {
		parent = document.elementFromPoint(x,y);
		log += "Got parent from point";
	}
	if( !parent ) {
		return null;
	}

	//var threadednote = document.createElement( "div" );
	//threadednote.className = 'threadednote';

	//threadednote.appendChild(NTIInlineNoteCreateDomElement(note))

	if( doBefore ) {
		log += " doBefore; ";
		if( parent.nextSibling ) {
			log += " nextSibling; ";
			//parent.parentElement.insertBefore( threadednote, parent.nextSibling );
		}
		else {
			//parent.parentElement.insertBefore( threadednote, parent );
		}
	}
	else {
		log += " do direct; ";
		//parent.appendChild( threadednote );
	}

	//window.setTimeout( function() { $(threadednote).removeClass( 'hidden' ); },
	//				   100 );

	//Find the nearest anchor point
	var anchorPoint = null, anchorType = null;
	console.log( parent );
	if( parent['id'] ) {
		anchorPoint = parent['id'];
		anchorType = 'id';
	}
	// TODO: This does not handle encountering a text node.
	else if( parent.previousSibling && parent.previousSibling['name'] ) {
		anchorPoint = parent.previousSibling['name'];
		anchorType = 'previousName';
	}
	//Try to go one further up
	else if( parent.previousSibling && parent.previousSibling.previousSibling && parent.previousSibling.previousSibling['name'] ) {
		anchorPoint = parent.previousSibling.previousSibling['name'];
		anchorType = 'previousPreviousName';
	}
	else {
		log += " up three, no anchor; ";
		if( parent.previousSibling ) { log += "; prevSib: " + parent.previousSibling; }
		if( parent.previousSibling.previousSibling ) { log += "; prevSib: " + parent.previousSibling.previousSibling; }
	}
	return JSON.stringify( [anchorPoint, anchorType, log] );
}

function NTIInlineNoteShowThreadAtAnchor( thread, anchorPoint, anchorType )
{
	var parent = null;
	//TODO: Error handling.
	try {
		if( anchorType == 'id' ) {
			parent = document.getElementById( anchorPoint );
		}
		else if( anchorType == 'previousName' ) {
			var anchor = $('a[name='+anchorPoint+']')[0];
			parent = anchor.nextSibling;
		}
		else if( anchorType == 'previousPreviousName' ) {
			var anchor = $('a[name='+anchorPoint+']')[0];
			parent = anchor.nextSibling.nextSibling;
		}

		var threadedNote = document.createElement('div');
		threadedNote.className = 'threadednote';

		NTIInlineNoteCreateThreadAsChild(threadedNote, thread);

		$(threadedNote).removeClass('hidden');
		$(parent).append( threadedNote );
		return "Displayed note " + threadedNote.outerHTML
			+ " at " + anchorPoint + "/" + NTIGetHTMLElementPosition( threadedNote )
			+ " under " + parent + " at " + NTIGetHTMLElementPosition( parent );
	}
	catch( e ) {
		return "Failed to display: " + e;
	}
}


function NTIDocumentPointAtAnchor(anchorPoint, anchorType)
{
	var parent = null;
	//TODO: Error handling.
	try {
		if( anchorType == 'id' ) {
			parent = document.getElementById( anchorPoint );
		}
		else if( anchorType == 'previousName' ) {
			var anchor = $('a[name='+anchorPoint+']')[0];
			parent = anchor.nextSibling;
		}
		else if( anchorType == 'previousPreviousName' ) {
			var anchor = $('a[name='+anchorPoint+']')[0];
			parent = anchor.nextSibling.nextSibling;
		}

		var result = null;
		if( parent ) {
			result = NTIGetHTMLElementPosition(parent);
		}
		else {
			result = [-1, -1];
		}

	}
	catch( e ) {
		result = [-1, -1];
	}
	result =  JSON.stringify(result);
	return result;
}

function NTIDebugEltAtPt( x, y )
{
	var parent = document.elementFromPoint(x,y);
	if( !parent ) {
		return "No element at " + x + " and " + y;
	}

	return parent.outerHTML;
}

function NTIInlineNoteGetAt( x, y )
{
	var note = NTIInlineNoteFind( x, y );

	var result = null;
	if(note){
		result = [note.id, note.innerHTML]
	}

	return JSON.stringify(result);
}

function NTIInlineNoteFind( x, y )
{
	var result = null;
	var e = document.elementFromPoint(x,y);
	while( e ) {
		if( e.tagName == 'DIV' && $(e).hasClass( 'inlinenote' ) ) {
			result = e;
			break;
		}
		e = e.parentNode;
	}
	return result;
}

function NTIInlineNoteDelete( x, y )
{
	var note = NTIInlineNoteFind( x, y );
	if( note ) {
		note.parentNode.removeChild( note );
	}
}

function NTIInlineNoteDeleteAll()
{
	var notes = $(".threadednote" );
	for( var i = 0; i < notes.length; i++ ) {
		notes[i].parentNode.removeChild( notes[i] );
	}
}

function NTIInlineNoteUpdate( note, x, y )
{
	var toUpdate = NTIInlineNoteByID(note.id)
	if( toUpdate ) {
		//Can't replace the entire innerHTML
		var childNotes = $('.inlinenote', toUpdate)
		toUpdate.innerHTML = note.text;
		for(var i=0;i<childNotes.length;i++){
			toUpdate.appendChild(childNotes[i]);
		}
	}
}



/**
 * Returns an x,y (or left,top) pair giving the absolute position of the
 * element on the page
 */
function NTIGetHTMLElementPosition( element )
{
	var offset = $( element ).offset();
	return [offset.left, offset.top];
}

/**
 * Returns a JSON list of six element tuples, (x,y,width,height,id) giving
 * the position and ID of each element matched by the given
 * jQuery selector. Because our usual purpose is to draw on top of on existing
 * item, we must return its client width and height for an exact match.
 */
function NTIGetHTMLElementPositionsAndIds( selector )
{
	var result = [];
	var nodes = $(selector);
	for( var i = 0; i < nodes.length; i++ ) {
		var elem = nodes[i];
		var pos = NTIGetHTMLElementPosition( elem );

		pos.push(elem.clientWidth > 0 ? elem.clientWidth : elem.offsetWidth);
		pos.push(elem.clientWidth > 0 ? elem.clientHeight : elem.offsetHeight);

		pos.push( elem.id );
		result.push( pos );
	}
	return JSON.stringify( result );
}

/**
 * Disables a group of elements and sets their opacity to 0.
 */
function NTIDisableAndMakeTransparentElements( selector )
{
	var nodes = $(selector);
	for( var i = 0; i < nodes.length; i++ ) {
		var elem = nodes[i];
		elem.style.opacity = 0;
		elem.disabled = true;
	}
}

/**
 * Makes a group of elements zero size and not displayed.
 */
function NTIHideAndMakeZeroSizeElements( selector )
{
	$(selector).addClass( 'hidden' );
	return true;
}

var NTIOnClick = 'ntionclick';

function NTIDisableAndHideSubmit( selector )
{
	var nodes = $(selector);
	nodes.removeAttr('href');
	var onclick = nodes.attr('onclick');
	nodes.removeAttr('onclick');
	nodes.attr(NTIOnClick, onclick);
	nodes.css('opacity', 0);
}

/**
 * stuff values into input elements
 */
function NTISubmitOverlayedForm( answers, inputSel, submitSel )
{
	var inputs = $(inputSel);


	for( var i = 0; i < inputs.length; i++ ) {
		var input = inputs[i];
		input.value = answers[input.id];

	}

	var event = {};
	event.preventDefault = $.noop;
	eval($(submitSel).attr(NTIOnClick));
	return true;
}

function NTIGetHTMLElementsAtPoint( x, y )
{
	var tags = [];
	var e = document.elementFromPoint(x,y);
	while( e ) {
		if( e.tagName ) {
			tags.push( e.tagName );
		}
		e = e.parentNode;
	}
	return JSON.stringify( tags );
}

/**
 * Given a starting containing element, see if the user clicked on a text node.
 */
function isWordAtPoint(elem, x, y)
{
	var result = false;
	if( elem.nodeType == elem.TEXT_NODE ) {
		var range = elem.ownerDocument.createRange();
		range.selectNodeContents(elem);
		var currentPos = 0;
		var endPos = range.endOffset;
		while( currentPos + 1 < endPos) {
			range.setStart(elem, currentPos);
			range.setEnd(elem, currentPos + 1);
			if(		range.getBoundingClientRect()
				&&	range.getBoundingClientRect().left <= x
				&&	range.getBoundingClientRect().right	 >= x
				&&	range.getBoundingClientRect().top	<= y
				&&	range.getBoundingClientRect().bottom >= y ) {
				range.expand("word");
				result = true;
				range.detach();
				break;
			}
			currentPos += 1;
		}
	}
	else {
		for( var i = 0; i < elem.childNodes.length; i++) {
			var range = elem.childNodes[i].ownerDocument.createRange();
			range.selectNodeContents(elem.childNodes[i]);
			if(		range.getBoundingClientRect().left <= x
				&&	range.getBoundingClientRect().right	 >= x
				&&	range.getBoundingClientRect().top	<= y
				&&	range.getBoundingClientRect().bottom >= y ) {
				range.detach();
				result = isWordAtPoint(elem.childNodes[i], x, y);
				break;
			}
			else {
				range.detach();
			}
		}
	}
	return result;
}

function NTIIsPointInteresting( x, y )
{
	//Walk up the DOM, see if there is anything that wants to
	//handle a click or touch
	//NOTE: This is broken if addEventListener is used.
	var elem = document.elementFromPoint(x,y);
	var e = elem;
	while( e ) {
		if(		e.onclick
			||	e.ontouchstart
			||	e.ontouchend
			||	e.ontouchmove
			||	(e.tagName == 'A' && e.hasAttribute('href'))
			||	e.className == 'timestamp') {
			return true;
		}
		e = e.parentNode;
	}
	//Not an interesting element, see if it was
	//plain text
	//return isWordAtPoint( elem, x, y );
	//Actually, now, we don't consider plain text interesting.
	return false;
}

function NTIIsPointHighlighted( x, y )
{
	var result = false;
	var e = document.elementFromPoint(x,y);
	while( e ) {
		if( e.tagName == 'SPAN' && $(e).hasClass( 'highlight' ) ) {
			result = true;
			break;
		}
		e = e.parentNode;
	}
	return result;
}

function NTIIsPointInlineNote( x, y )
{
	var result = false;
	if( NTIInlineNoteFind( x, y ) ) {
		result = true;
	}

	return result;
}

function NTIIsPointHighlightedOrInteresting( x, y )
{
	return NTIIsPointHighlighted( x, y ) || NTIIsPointInteresting( x, y ) || NTIIsPointInlineNote( x, y );
}

$.extend($.expr[':'], {
	focused: function(elem) { return elem.hasFocus; }
});

function NTITextareaHasFocus()
{
	return $("textarea:focused").length > 0;
}

function NTIHighlightSelection( dataserver, user, password )
{
	/*
	$.ajax({type: 'POST',
			url: dataserver + '/latesthl',
			data: window.getSelection().toString(),
			username: user,
			password: password,
			contentType: 'text/plain'});
	*/
	translateSelectAndSave(dataserver, user, password);
}

function NTIRemoveHighlightAt( x, y )
{
	var e = document.elementFromPoint(x,y);
	var highlightID = traverseToRemoveHighlight(e);

	//Remove the object from the local and server storage
	deleteObjectWithId(username, NTIHighlightType, highlightID);
}

function climbToTheHighlitableNode(node)
{
	var math = climbToMathNode(node);
	if(math != null)
	{
		return math;
	}
	else if(node.nodeName == "IMG")
	{
		return node;
	}
	else {
		return null;
	}
}

function traverseToRemoveHighlight(startingNode)
{
	//Find the starting Node if we don't have a textnode
	if(!isTextNode(startingNode))
	{
		var snode = climbToTheHighlitableNode(startingNode);
		if(snode != null)
		{
			startingNode = snode;
		}

	}
	var highlightID = retrieveHighlightID(startingNode);

	// Find the anchor of the starting node
	var startAnchor = ascendToAnchor(startingNode);
	var listOfPreviousNodes = [];
	if(startAnchor != null)
	{
		//Generate the whole map
		var anchorToNodeMap = mapTextToAnchors();
		var foundStartAnchor = false;
		var startNodeFound = false;
		var keepLooking = false;
		var isHighlighted = false;
		//var checkingAnchorDone = false;
		//locate the startAnchor in the map of anchors
		for (var key in anchorToNodeMap) {
			if(key == startAnchor)
			{
				foundStartAnchor = true;
				for(var i=0; i < anchorToNodeMap[key].length; i++) {
					//For comparing text nodes
					if(startingNode.textContent == anchorToNodeMap[key][i].nodeValue){
						// Found the starting node, so start to loop through: checking both the left and the right
						startNodeFound = true;

						//Unhightlight all the nodes of the current anchor starting from startingNode
						keepLooking = removeAnchorHighlight(anchorToNodeMap[key], i, 1);
						//Check previous nodes
						if(keepLooking == false)
						{
							// Check if any of the previous nodes was part of the highlighted section
							keepLooking = removeAnchorHighlight(listOfPreviousNodes, 0, -1);
							break;
						}
						//Get out of the loop because we have already checked all the nodes in this anchor
						if(keepLooking == true) {
							break;
						}

					}
					// For comparing mathjax nodes
					else if(startingNode.outerHTML == anchorToNodeMap[key][i].outerHTML) {
						// Found the starting node, so start to loop through: checking both the left and the right
						startNodeFound = true;

						keepLooking = removeAnchorHighlight(anchorToNodeMap[key], i, 1);
						if(keepLooking == false)
						{
							// Check if any of the previous nodes was part of the highlighted section
							keepLooking = removeAnchorHighlight(listOfPreviousNodes, 0, -1);
							break;
						}
						//Get out of the loop because we have already checked all the nodes in this anchor
						if(keepLooking == true) {
							break;
						}
					}
					else {
						listOfPreviousNodes.push(anchorToNodeMap[key][i]);
					}

				}
			}
			//keep looking on the right
			else if(startNodeFound && keepLooking == true)
			{
				keepLooking = removeAnchorHighlight(anchorToNodeMap[key], 0, 1);
			}
			//We have found the startNode and keeplooking is false, because we just finished looking for all the associated nodes on the right.
			// Now we need to check the nodes on the left the starting node
			else if(startNodeFound && !keepLooking)
			{
				keepLooking = removeAnchorHighlight(listOfPreviousNodes, 0, -1);
				break;
			}
			else if(!startNodeFound && !keepLooking)
			{
				//add the nodes to the list of nodes to check from the starting node to the right
				for(var x = 0; x < anchorToNodeMap[key].length; x++) {
					listOfPreviousNodes.push(anchorToNodeMap[key][x]);
				}
			}

		}
	}

	//return the highlight ID to be removed as well
	return highlightID;

}


function removeAnchorHighlight(anchorNodes, startIndex, direction)
{
	var keepLooking = false;
	//Move left to right of the given node
	if(direction == 1)
	{
		var wasHighlighted = true;
		for(var k = startIndex; (k < anchorNodes.length) && wasHighlighted; k++) {
			wasHighlighted =  unHighlightNode(anchorNodes[k]);
			if(wasHighlighted == null)
			{
				//unkown element: not a textnode, mathnode, or ImageNode
				console.log(anchorNodes[k].nodeName);
				wasHighlighted = false;
			}

		}
	}
	//Move right to left of the given node
	else if(direction == -1) {
		var wasHighlighted = true;
		for(var k = (anchorNodes.length - 1); (k >=0 ) && wasHighlighted; k--) {
			wasHighlighted =  unHighlightNode(anchorNodes[k]);
			if(wasHighlighted == null)
			{
				//unkown element: not a textnode, mathnode, or ImageNode
				console.log(anchorNodes[k].nodeName);
				wasHighlighted = false;
			}

		}

	}

	//keepLooking tells the caller whether or not this is the endAnchor to look into
	// If keepLooking is false: this the last/first anchor to look into
	// If keepLooking is true: this is a middle anchor
	keepLooking = wasHighlighted;
	return keepLooking;

}

function unHighlightNode(node) {
	if(isTextNode(node)){
		var e = node.parentNode;
		if( e.tagName == 'SPAN' && $(e).hasClass('highlight')) {
			var child = e.firstChild;
			e.removeChild( child );
			e.parentNode.replaceChild( child, e);
			return true;

		} else {
			return false;
		}
	}
	else if(isMathNode(node)){
		var nodeWithHighlight = node.parentNode;
		if($(nodeWithHighlight).hasClass('highlight') ) {
			$(nodeWithHighlight).removeClass('highlight');
			return true;
		}
		else {
			return false;
		}
	}
	else if(isImageNode(node)) {
		if($(node).hasClass('highlight') ) {
			$(node).removeClass('highlight');
			return true;
		}
		else {
			return false;
		}
	}
	else
	{
		return null;
	}


}

function retrieveHighlightID(node)
{
	var nodeWithHighlight = $(node).hasClass( 'highlight' ) ? node : node.parentNode;

	if( $(nodeWithHighlight).hasClass('highlight') ) {
		var cnameArray = nodeWithHighlight.className.split(" ");
		var hid = cnameArray[1];
		hid = parseInt(hid);
		return hid;
	}

	return null;

}

function changeFontSize( add  )
{
	var size = document.getElementsByTagName("body")[0].style.fontSize;
	if( !size ) {
		size = "100%";
	}
	size = parseInt( size.replace("%", "") );
	if( add ) {
		size = size + 10;
	}
	else {
		size = size - 10;
	}
	size = size + "%";
	document.getElementsByTagName( "body" )[0].style.fontSize = size;
	return size;
}


/**
 * @return A string representing the new font size.
 */
function NTIIncreaseFontSize()
{
	return changeFontSize( true );
}

/**
 * @return A string representing the new font size.
 */
function NTIDecreaseFontSize()
{
	return changeFontSize( false );
}

/**
 * @param size A string as returned from NTIDecreaseFontSize
 */
function NTISetFontSize( size )
{
	document.getElementsByTagName( "body" )[0].style.fontSize = size;
}

function NTISetFontFace( face )
{
	document.getElementsByTagName( "body" )[0].style.fontFamily = face;
}

//NOTE1: Palatino and Open Sans do not include all the glyphs necessary,
//and the iPad doesn't do automatic-font-substititon, as the browser does.
//Therefore, you must specify the entire fallback list.
//NOTE2: If the math is generated with STIX fonts, the metrics for other
//fonts will not work. This is most noticeable with square roots, but
//also impacts other fonts, including Quivira. We would typically leave
//this disabled, then, but for testing we make it a setting.
var NTISerifMathFace = "Palatino, Quivira, STIXGeneral, ntimarkerface";
var NTISansSerifMathFace = "'Open Sans', MathJax_SansSerif, Quivira, STIXGeneral, ntimarkerface";
var NTIShouldUseMathFace = false;

function NTISetShouldUseMathFace( use )
{
	//called from objc, we get a string
	if( !use || "false" == use ) {
		NTIShouldUseMathFace = false;
	}
	else {
		NTIShouldUseMathFace = true;
	}
	return NTIShouldUseMathFace;
}

function NTISetSansSerifMath()
{
	if( !NTIShouldUseMathFace ) {
		return;
	}

	var mathEls = $(".math span");
	for( var i = 0; i < mathEls.length; i++ ) {
		if( mathEls[i].style.fontFamily == NTISerifMathFace )
			mathEls[i].style.fontFamily = NTISansSerifMathFace;
		else if( mathEls[i].style.fontFamily == 'STIXGeneral' )
			mathEls[i].style.fontFamily = "MathJax_Size1";
		else if( mathEls[i].style.fontFamily == 'STIXSizeOneSym' )
			mathEls[i].style.fontFamily = 'MathJax_Size2';
		else if( mathEls[i].style.fontFamily == 'STIXSizeTwoSym' )
			mathEls[i].style.fontFamily = 'MathJax_Size3';
		else if( mathEls[i].style.fontFamily == 'STIXSizeThreeSym' )
			mathEls[i].style.fontFamily = 'MathJax_Size4';
	}
}

function NTISetSerifMath()
{
	if( !NTIShouldUseMathFace ) {
		return;
	}

	var mathEls = $(".math span");
	for( var i = 0; i < mathEls.length; i++ ) {
		if( mathEls[i].style.fontFamily == NTISansSerifMathFace )
			mathEls[i].style.fontFamily = NTISerifMathFace;
		else if( mathEls[i].style.fontFamily == 'MathJax_Size1' )
			mathEls[i].style.fontFamily = "STIXGeneral";
		else if( mathEls[i].style.fontFamily == 'MathJax_Size2' )
			mathEls[i].style.fontFamily = 'STIXSizeOneSym';
		else if( mathEls[i].style.fontFamily == 'MathJax_Size3' )
			mathEls[i].style.fontFamily = 'STIXSizeTwoSym';
		else if( mathEls[i].style.fontFamily == 'MathJax_Size4' )
			mathEls[i].style.fontFamily = 'STIXSizeThreeSym';
	}
}

function NTIInitMathFace()
{
	//Resize embedded math regardless of face choice
	//See comments in NTIOnStateSet about how slow this is.
	var mathEls = $("span.math span[style*='font-size: 116']");
	for( var i = 0; i < mathEls.length; i++ ) {
		mathEls[i].style.fontSize = '100%';
	}

	if( !NTIShouldUseMathFace ) {
		return;
	}
	mathEls = $(".math span");
	for( i = 0; i < mathEls.length; i++ ) {
		if( mathEls[i].style.fontFamily == 'STIXGeneral' )
			mathEls[i].style.fontFamily = NTISansSerifMathFace;
	}


}


function NTIShowNotes()
{
	$(".note").removeClass( "hiddenNote" );
	Note.onnotesloaded = NTIShowNotes;
}

function NTIHideNotes()
{
	$(".note").addClass( "hiddenNote" );
	Note.onnotesloaded = NTIHideNotes;
}


var captured = null;
var highestZ = 0;

function Note()
{
	var self = this;

	var note = document.createElement('div');
	note.className = 'note';
	note.addEventListener('touchstart', function(e) { return self.touchStart(e); }, false);
	note.addEventListener('touchmove', function(e) { return self.touchMove(e); }, false);
	note.addEventListener('touchend',function(e){ return self.touchEnd(e); }, false);
	note.addEventListener('click', function() { return self.onNoteClick(); }, false);
	this.note = note;

	var close = document.createElement('div');
	close.className = 'closebutton';
	close.addEventListener('click', function(event) { return self.close(event); }, false);
	note.appendChild(close);
	this.closebutton = close;

	var edit = document.createElement( 'textarea' );
	edit.className = 'edit';
	//Mobile safari doesn't support contenteditable
	//edit.setAttribute('contenteditable', true);
	edit.addEventListener('keyup', function() { return self.onKeyUp(); }, false);

	note.appendChild( edit );
	this.editField = edit;

	var ts = document.createElement('div');
	ts.className = 'timestamp';
	//ts.addEventListener('touchstart', function(e) { return self.touchStart(e); }, false);
	//ts.addEventListener( 'click', function() { return self.maximizeNote(); }, false );
	ts.onclick = function() { return self.minimizeNote(); };
	note.appendChild(ts);
	this.lastModified = ts;

	edit.addEventListener( 'blur', function() {
							   //because minimizing toggles the clickability of the close button
							   setTimeout( function() { self.minimizeNote(); }, 200 );
							   return true;
	}, false );

	document.body.appendChild(note);
	return this;
}


Note.prototype = {
	get ID()
	{
		//It is critical we don't generate
		//ids ourself. Anything we choose, e.g., 0,
		//will lead to a wrong PUT on top of a possibly
		//existing object.
		if( !("_id" in this) ) {
			this._id = null;
		}
		return this._id;
	},

	set ID(x)
	{
		this._id = x;
	},

	get text()
	{
		return this.editField.value;
	},

	set text(x)
	{
		this.editField.value = x;
	},

	get modifiedtime()
	{
		if (!("_modifiedtime" in this))
			this._modifiedtime = 0;
		return this._modifiedtime;
	},

	set modifiedtime(x)
	{
		if (this._modifiedtime == x)
			return;

		this._modifiedtime = x;
		var date = new Date();
		date.setTime(parseFloat(x));
		this.lastModified.textContent = modifiedString(date);
	},

	get left()
	{
		return this.note.style.left;
	},

	set left(x)
	{
		this.note.style.left = x;
	},

	get top()
	{
		return this.note.style.top;
	},

	set top(x)
	{
		this.note.style.top = x;
	},

	get zIndex()
	{
		return this.note.style.zIndex;
	},

	set zIndex(x)
	{
		this.note.style.zIndex = x;
	},

	minimizeNote: function()
	{

		var trimmedText=~$.trim(this.text);

		if(this.close != Note.prototype.minimizeNote && !trimmedText)
		{
			this.close({});
			return false;
		}
		else {

			$(this.note).addClass( 'minimizedNote' );
			$(this.closebutton).addClass( 'minimizedElement' );
			var date = new Date();
			date.setTime( parseFloat( this._modifiedtime ) );
			//console.log(this);
			this.lastModified.textContent = shortModifiedString( date );
			this.save();
			var self = this;
			this.lastModified.onclick = function() { self.maximizeNote(); };
			return false;
		}

	},

	maximizeNote: function()
	{
		$(this.note).removeClass( 'minimizedNote' );
		$(this.closebutton).removeClass( 'minimizedElement' );
		var date = new Date();
		date.setTime( parseFloat( this._modifiedtime ) );
		this.lastModified.textContent = modifiedString( date );
		var self = this;
		this.lastModified.onclick = function() { self.minimizeNote(); };

		return false;

	},

	close: function(event)
	{

		this.cancelPendingSave();

		var note = this;
		deleteObject(username, NTINoteType,note);

		var duration = event.shiftKey ? 2 : .25;
		this.note.style.webkitTransition = '-webkit-transform ' + duration + 's ease-in, opacity ' + duration + 's ease-in';
		this.note.offsetTop; // Force style recalc
		this.note.style.webkitTransformOrigin = "0 0";
		this.note.style.webkitTransform = 'skew(30deg, 0deg) scale(0)';
		this.note.style.opacity = '0';

		var self = this;
		setTimeout(function() { document.body.removeChild(self.note); }, duration * 1000);

	},

	saveSoon: function()
	{
		this.cancelPendingSave();
		var self = this;
		this._saveTimer = setTimeout(function() { self.save(); }, 200);
	},

	cancelPendingSave: function()
	{
		if (!("_saveTimer" in this))
			return;
		clearTimeout(this._saveTimer);
		delete this._saveTimer;
	},

	save: function()
	{
		this.cancelPendingSave();
		//console.log('Considering saving');
		if ("dirty" in this) {
			var date = new Date();
			//console.log('Saving');
			this.modifiedtime = date.getTime();

			delete this.dirty;

			if($(this.note).hasClass('minimizedNote'))
			{
				this.lastModified.textContent = shortModifiedString( date );
			}
			else
			{
				this.lastModified.textContent = modifiedString( date );
			}

			var note = this;
			persistObject(username, NTINoteType,note,
						  function(obj){
						  },
						  function(){
							  console.log('An error occurred persisting notes');
							  console.log(arguments);
						  });
		}
	},

	saveAsNew: function()
	{
		//this.timestamp = new Date().getTime();

		//var note = this;
		//saveAsNewNote(note);
	},

	touchStart: function(e)
	{
		captured = this;
		this.startX = e.targetTouches[0].pageX - this.note.offsetLeft;
		this.startY = e.targetTouches[0].pageY - this.note.offsetTop;
		this.zIndex = ++highestZ;
		return false;
	},

	touchMove: function(event)
	{
		this.dirty = true;
		event.preventDefault();
		var curX = event.targetTouches[0].pageX - this.startX;
		var curY = event.targetTouches[0].pageY - this.startY;

		this.left = curX + 'px';
		this.top = curY + 'px';
		//this.save();
		return false;
	},

	touchEnd: function(event)
	{
		this.save();
	},

	onNoteClick: function(e)
	{
		//this.maximizeNote();
		//this.editField.focus();
		//getSelection().collapseToEnd();
	},

	onKeyUp: function()
	{
		this.dirty = true;
		//this.saveSoon();
	},

	toPersistenceObject: function()
	{
		var note = this;
		return {
			'ID': note.ID,
			'text': note.text,
			'Last Modified': note.modifiedtime,
			'left' : note.left,
			'top' : note.top,
			'zIndex' : note.zIndex
		};
	},

	fromPersistenceObject: function(pObj)
	{
		var note = new Note();
		note.ID = pObj['ID'];
		note.text = pObj['text'];
		note.modifiedtime = pObj['Last Modified']*1000;
		note.left = pObj['left'];
		note.top = pObj['top'];
		note.zIndex = pObj['zIndex'];

		note.minimizeNote();

		return note;
	},

	makeReadOnly: function()
	{

		this.close=Note.prototype.minimizeNote;
		this.save=$.noop;

		//this.closebutton.style.display = 'none';
		this.editField.disabled = true;
	},

	styleAsShared: function()
	{
		this.editField.style.backgroundColor='#33CCFF';
		this.note.style.backgroundColor="#33CCFF";
		this.lastModified.style.backgroundColor='#3399FF';
		this.lastModified.style.borderTop='1px solid #3399FF';
	}

};

Note.onnotesloaded = NTIHideNotes;

var formatDate = function (formatDate, formatString) {
	if(formatDate instanceof Date) {
		var months = new Array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
		var yyyy = formatDate.getFullYear();
		var yy = yyyy.toString().substring(2);
		var m = formatDate.getMonth();
		var mm = m < 10 ? "0" + m : m;
		var mmm = months[m];
		var d = formatDate.getDate();
		var dd = d < 10 ? "0" + d : d;
		var h = formatDate.getHours();
		var hh = h < 10 ? "0" + h : h;
		var n = formatDate.getMinutes();
		var nn = n < 10 ? "0" + n : n;
		var s = formatDate.getSeconds();
		var ss = s < 10 ? "0" + s : s;

		formatString = formatString.replace(/yyyy/i, yyyy);
		formatString = formatString.replace(/yy/i, yy);
		formatString = formatString.replace(/mmm/i, mmm);
		formatString = formatString.replace(/mm/i, mm);
		formatString = formatString.replace(/m/i, m);
		formatString = formatString.replace(/dd/i, dd);
		formatString = formatString.replace(/d/i, d);
		formatString = formatString.replace(/hh/i, hh);
		formatString = formatString.replace(/h/i, h);
		formatString = formatString.replace(/nn/i, nn);
		formatString = formatString.replace(/n/i, n);
		formatString = formatString.replace(/ss/i, ss);
		formatString = formatString.replace(/s/i, s);

		return formatString;
	} else {
		return "";
	}
}

function modifiedStringWithPrefix(date, prefix)
{
	return prefix + formatDate(date, 'yyyy-mm-dd hh:nn:ss');
}

function modifiedString(date)
{
	return modifiedStringWithPrefix( date, 'Last Modified: ' );
}

function shortModifiedString(date)
{
	return formatDate('mm/dd/yyyy');
}

var NTINoteType = 'Notes';
var NTIHighlightType = 'Highlights';

function NTINewNote(x, y)
{
	var note = new Note();
	note.ID = null;
	note.lastmodified = new Date().getTime();
	note.left = x + 'px';
	note.top = y + 'px';
	note.zIndex = ++highestZ;
	return note;
}

function NTIEditLastNote()
{
	//FIXME: We'd like to drop the selection and focus the textfield,
	//but mobile safari doesn't support this--it winds up with two selections,
	//the original /and/ the paragraph, which is awkward and ugly
}

function NTIMinimizeNotes()
{
	$(".note").addClass( "minimizedNote" );

}



function getObjects(user, type, obj, modifiedSince, success, error){

	var modifiedHeader = {};
	//FIXME: Something is broken in jQuery. If we even supply the
	//'headers' key at all, something breaks with the Authorization
	//set by the beforeSend hook. Thus, we must set it in the
	//headers dictionary in order for CORS to work.
	//FIXME: Safari 5.0.5 doesn't set the Origin header. Nightly is fine,
	//chrome 13 is fine. Firefox 4 and 5 flat out won't load the WebUI at all.
	modifiedHeader['Authorization'] = "Basic " + Base64.encode( username + ":" + password );
	if(modifiedSince) {
		modifiedHeader['If-Modified-Since'] = modifiedSince.toUTCString();
	}

	$.ajax(
		{
 			type: 'GET',
			url: formDataServerURL(user, type, NTIGetPageID(), obj),
 			headers: modifiedHeader,
			crossDomain: true,
   			error: error,
			success: function(data, textStatus, jqXHR){
				var json = JSON.parse(data);
				success(json);
			}
		});
}

function persistObject(user,type, obj, success, error){
	var ajaxType = null;
	var objID = null;

	var pObj = obj;
	if(obj.toPersistenceObject)
	{
		pObj = obj.toPersistenceObject();
	}

	var filteredObj = {};
	for (var key in pObj) {
		if( (!pObj.hasOwnProperty(key) || !pObj[key]) && pObj[key] != "" ) continue;
		filteredObj[key] = pObj[key];
	}

	if(typeof(pObj.ID) === 'undefined' || pObj.ID == null)
	{
		ajaxType = 'POST';
	}
	else
	{
		ajaxType = 'PUT';
		objID = pObj.ID;
	}

	$.ajax({type: ajaxType,
			 url: formDataServerURL(user, type, NTIGetPageID(), objID),
			 data: JSON.stringify(filteredObj),
   			 error: error,
			 success: function(data, textStatus, jqXHR){
				var localObjs=objectsFromLocalStorage(type);

				var json = JSON.parse(data);

				obj.ID=json.ID;
				obj.lastmodified=json['Last Modified'];

				localObjs[json.ID]=json;
				localObjs['Last Modified']=json['Last Modified'];

				persistObjectsDictionaryToLocalStorage(type, localObjs);

				success(json);

			 }});

}

function deleteObject(user, type, obj, success, error)
{

	var pObj = obj;
	if(obj.toPersistenceObject)
	{
		pObj = obj.toPersistenceObject();
	}

	if(typeof(pObj.ID) === 'undefined' || pObj.ID == null)
	{
		return;
	}

	 //Delete from server
	 $.ajax({type: 'DELETE',
			 url: formDataServerURL(user, type, NTIGetPageID(), pObj.ID),
		     error: error,
			 success: function(data, textStatus, jqXHR){
				 var localObjs=objectsFromLocalStorage(type);

				 var lastModified = new Date(jqXHR.getResponseHeader('Last Modified')).getTime()/1000; //js gives us millis since epoch.  We want seconds

				 localObjs['Last Modified']=lastModified;
				 delete localObjs[pObj.ID];
				 //console.log(lastModified);
				 persistObjectsDictionaryToLocalStorage(type, localObjs);
			 }});
}

function deleteObjectWithId(user, type, objID, success, error)
{
	//Delete from server
	$.ajax({type: 'DELETE',
			url: formDataServerURL(user, type, NTIGetPageID(), objID),
			error: error,
			success: function(data, textStatus, jqXHR){
			   var localObjs = objectsFromLocalStorage(type);

			   var lastModified = new Date(jqXHR.getResponseHeader('Last Modified')).getTime()/1000; //js gives us millis since epoch.  We want seconds

			   localObjs['Last Modified']=lastModified;
			   delete localObjs[objID];
			   //console.log(lastModified);
			   persistObjectsDictionaryToLocalStorage(type, localObjs);
		   }});
}

function formDataServerURL(user, datatype, group, id)
{

	var url = dataserver;
	if( !url ) {
		return null;
	}
	if( url[url.length - 1] != '/')
	{
		url += '/';
	}

	url += 'users/'+user;

	if(datatype)
	{
		url+='/'+datatype;
		if(group)
		{
			url+='/'+group;
			if(typeof(id)!=='undefined' && id!=null)
			{
				url+='/'+id;
			}
		}
	}

	return url+'?format=json';
}

//Returns a dictionary of id -> obj.  In addtion a special id of Last Modified provides
//the last modified time {Last Modified, id1->obj1, id2->obj2...}
function objectsFromLocalStorage(type){

	var localObjsString = localStorage[type];

	var localObjs = {};

	if(localObjsString != null)
	{
		localObjs = JSON.parse(localObjsString);
	}

	var pageObjs = localObjs[NTIGetPageID()];

	if(pageObjs == null)
	{
		return {'Last Modified':0};
	}
	else
	{
		return pageObjs;
	}
}

//See above for expected format of objsDict
function persistObjectsDictionaryToLocalStorage(type, objsDict){
	var localObjsString = localStorage[type];

	var localObjs = {};

	if(localObjsString != null)
	{
		localObjs = JSON.parse(localObjsString);
	}

	localObjs[NTIGetPageID()] = objsDict;

	localStorage[type] = JSON.stringify(localObjs);
}


function loadSharedObjects(user, type, create)
{
	getObjects(user, type, null, null,
			   function(result)
			   {
				   var items=result['Items'];
				   for(id in items)
				   {
					   if(id == 'Last Modified')
					   {
						   continue;
					   }
					   //console.log(items[id]);
					   var obj = create(items[id]);
					   obj.makeReadOnly();
					   obj.styleAsShared();
				   }
			   },
			   function()
			   {
				   //If its a 404 this is ok
				   //alert('Unable to load shared objects of type '+type+' for user '+user);
			   });
}





var dataserver;
var username;
var password;
var NTISuppressNotes;
var NTIWidth = '730';

function NTIScrollDown()
{
	var fontSize = $("p").css('font-size');
	var lineHeight = Math.floor(parseInt(fontSize.replace('px','')) * 1.5);
	window.scrollBy( 0, document.documentElement.clientHeight - 2 * lineHeight );
}


function NTIScrollUp()
{
	var fontSize = $("p").css('font-size');
	var lineHeight = Math.floor(parseInt(fontSize.replace('px','')) * 1.5);
	window.scrollBy( 0, -1 * (document.documentElement.clientHeight - 2 * lineHeight) );
}

function NTIGetPageID()
{
	return $('meta[name=NTIID]').attr('content');
}

function NTIGetNextHref()
{
	return $('link[rel=next]').attr( 'href' );
}

function NTIGetPrevHref()
{
	return $('link[rel=prev]').attr( 'href' );
}

var friendsList=[];

function NTISetFriendsList(nameList)
{
	friendsList=nameList;
}

function NTIShowAttemptLabel( lastMod , percentage )
{
	if( lastMod ) {
		var date = modifiedStringWithPrefix( new Date( lastMod * 1000 ), "Attempt: " );
		var score = "Score: "+percentage.toFixed(1)+"%";
		var title = $(".worksheet-title")[0];
		if( document.getElementById( "timetaken" ) ) {
			title.removeChild( document.getElementById( "timetaken" ) );
		}
		var taken = document.createElement( "div" );
		taken.id = "timetaken";
		taken.innerHTML =  date+'   '+score;
		title.appendChild( taken );
	}
}

function NTIClearPriorAnswers( selector )
{
	var fields = $(selector);
	for( var i = 0; i < fields.length; i++ ) {
		//Remove previous stuff
		var root = fields[i].parentNode.parentNode;
		var toRemove = root.querySelectorAll( ".mathjax" );
		console.log( toRemove );
		for( var j = 0; j < toRemove.length; j++ ) {
			console.log( toRemove[j] );
			toRemove[j].parentNode.removeChild( toRemove[j] );
		}
	}
}

function NTIShowSubmittedAndCorrectAnswers( answers , selector)
{

	NTIClearPriorAnswers( selector );

	for( var i = 0; i < answers.length; i++ ){
		var answer = answers[i];
		var field = document.getElementById(answer.Question.ID);

		if( !field ){
			continue;
		}

		var root = field.parentNode.parentNode;
		//A boolean indicating whether the response was correct
		var right = answer['Assessment'];
		//An array of LaTeX expressions that can be displayed with MathJax
		var possibleAnswers = answer['Question']['Answers'];
		field.value = answer['Response'];
		$(field).addClass( "hidden" );

		var yourResponse = document.createElement( "div" );
		yourResponse.className = "mathjax tex2jax_process response";
		yourResponse.innerHTML = "You entered: \\(" + answer['Response'] + '\\)';
		var rightAnswer = document.createElement( "div" );
		rightAnswer.className = "mathjax tex2jax_process answer";
		rightAnswer.innerHTML = 'Correct answer: ';
		for( var a = 0; a < possibleAnswers.length; a++ ) {
			//Put in MathJax inline math format
			rightAnswer.innerHTML += possibleAnswers[a].replace( '$', '\\(' ).replace( '$', '\\)' );
			if( a + 1 < possibleAnswers.length ) {
				rightAnswer.innerHTML += ", ";
			}
		}

		var result = root.querySelector( ".result" );
		var doadd = false;
		if( !result ) {
			result = document.createElement( "div" );
			result.className = 'result';
			doadd = true;
		}

		var resultClass = right ? "correct" : "incorrect";

		$(result).addClass(resultClass);
		result.appendChild( yourResponse );
		result.appendChild( rightAnswer );
		if( doadd ) {
			root.appendChild( result );
		}
		$(result).removeClass( "hidden" );
	}
}

function NTIPresentAnswers( data, selector )
{
	var results = data;
	//A dictionary from question ID to result data
	var answers = results['Items'];
	
	try{

		var total = 0.0;
		var correct = 0.0;

		for( var i = 0; i < answers.length; i++ ){
			var answer = answers[i];
			if( answer.Assessment ){
				correct += 1;
			}
			total += 1;
		}

		NTIShowAttemptLabel( results['Last Modified'], (correct / total) * 100 );
	}catch( err ){
		console.log(err);
	}

	try{
		NTIShowSubmittedAndCorrectAnswers( answers, selector );
	}catch( err ){
		console.log(err);
	}

	try{
		//Have mathjax display the new math
		MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
	}catch( err ){
		console.log(err);
	}

}


function NTISubmitAnswers( evt, selector ) {
	evt.preventDefault();


	var fields = $(selector);
	//Dictionary from QuestionID to response
	var answers = {};
	for( var i = 0; i < fields.length; i++ ) {
		//The IDs of the fields MUST match the IDs in the quiz
		//Either the plain text or latex, or the OpenMath XML
		answers[fields[i].id] = fields[i].value;
	}

	persistObject( username, 'quizresults', answers, function( data, textStatus, jqXHR ) {
			NTIPresentAnswers( data, selector );
	});
	return false;
}

function NTIShowAnswers( evt, key )
{
	getObjects( username, 'quizresults', key, null, function( data ) {
		//FIXME: duplicating the selector here and in the page!
		NTIPresentAnswers( data, "input[type]" );
		$("a#submit").addClass( "hidden" );
	});

}

function NTIRetakeQuiz( evt )
{
	$("a#submit").removeClass( "hidden" );
	//FIXME: hardcoding again
	$('input[type]' ).removeClass( "hidden" );
	$(".result" ).addClass( "hidden" );
}

function _ntiCreateCheckFunction( key )
{
	return function( evt ) {
		evt.preventDefault();
		NTIShowAnswers( evt, key );
	};
}

function NTICheckForAnswers()
{
	getObjects( username, 'quizresults', null, null, function( data ) {
		var list = document.createElement( "ul" );
		list.id = 'previousattemptlist';
		var allResults = data;
		var lowestKey = "0";
		for( var key in allResults ) {
			if( key == "Last Modified" ) {
				continue;
			}
			if( key < lowestKey ) {
				lowestKey = key;
			}
			var itemDiv = document.createElement( "li");
			var itemA = document.createElement( "a" );
			var date = modifiedStringWithPrefix( new Date( allResults[key]['Last Modified'] * 1000 ), "Attempt: " );
			itemA.innerHTML += date;
			itemA.addEventListener( 'click', _ntiCreateCheckFunction( key ), false );
			itemA.href="#";
			itemDiv.appendChild( itemA );
			list.appendChild( itemDiv );
		}
		var itemDiv = document.createElement( "li" );
		var itemA = document.createElement( "a" );
		itemA.addEventListener( 'click', NTIRetakeQuiz, false );
		itemA.href="#";
		itemA.innerHTML = "Try Again";
		itemDiv.appendChild( itemA );
		list.appendChild( itemDiv );
		//$(".worksheet-title")[0].appendChild( list );
		var titleDiv = $(".worksheet-title")[0];
		var divAnchor = document.createElement( "a" );
		divAnchor.href="#";
		divAnchor.className = "worksheet-title";
		divAnchor.innerHTML = titleDiv.innerHTML;
		divAnchor.appendChild( list );
		divAnchor.addEventListener( 'click', function(evt) { $(list).toggleClass( "previousattemptsshow" ); }, false );
		titleDiv.parentNode.insertBefore( divAnchor, titleDiv );
		titleDiv.parentNode.removeChild( titleDiv );
		NTIShowAnswers( null, lowestKey );
	});

}


function NTIOnStateSet(ds, user, pwd)
{
	//Some of our functions now have side effects
	//we don't want to repeat as we move back and forth
	//Must store this globally since this file gets re-evalled
	if( window.hasOwnProperty('NTIOnStateSetCalled') ) {
		return;
	}
	window.NTIOnStateSetCalled = true;

	//set the device width if not set already
	if( !$('meta[name=viewport]').length || $('meta[name=viewport]')[0].content != NTIWidth ) {
		var meta = document.createElement( 'meta' );
		meta.name = 'viewport';
		meta.content = 'width=' + NTIWidth;
		document.head.appendChild( meta );
	}

	//FIXME: Initting the math face, which right now is
	//only resizing the inline math, is quite slow, up to a second on the longer
	//pages. We will move this into the generation of the static mathjax.
	//Until then, we will have a slightly too-big font.
	//NTIInitMathFace();

	dataserver = ds;
	username = user;
	password = pwd;

	//Setup defaults for jQuery AJAX
	//NOTE: The username cannot contain a
	//@: WebKit does BAD things--silently breaks.
	$.ajaxSetup(
		{
			username:  username.replace( '@', '%40' ),
			password: password,
			xhrFields: {
				withCredentials: "true"
			},
			beforeSend: function( xhr ) { xhr.setRequestHeader( "Authorization", "Basic " + Base64.encode( username + ":" + password ) ); },
			dataType: 'text'
		});

//This happens in objective c land now.
//	if( !NTISuppressNotes ) {
//		syncAndLoadNotes();
//	}
//
//	syncAndLoadHighlights();
}

/*
* Code for highlighting
*/

NextThought.Highlight = function() {
    var self = this;

	return self;
}

NextThought.Highlight.prototype = {
	get ID()
	{
		//It is critical we don't generate
		//ids ourself. Anything we choose, e.g., 0,
		//will lead to a wrong PUT on top of a possibly
		//existing object.
		if( !("_id" in this) ) {
			this._id = null;
		}
		return this._id;
	},

	set ID(x)
	{
		this._id = x;
	},

	get startAnchor()
	{
		if( !("_startAnchor" in this) ) {
			this._startAnchor = null;
		}
		return this._startAnchor;
	},

	set startAnchor(a)
	{
		this._startAnchor = a;
	},

	get startOffset()
	{
		if( !("_startOffset" in this) ) {
			this._startOffset = null;
		}
		return this._startOffset;
	},

	set startOffset(o)
	{
		this._startOffset = o;
	},

	get startHighlightedText()
	{
		if( !("_startHighlightedText" in this) ) {
			this._startHighlightedText = null;
		}
		return this._startHighlightedText;
	},

	set startHighlightedText(t)
	{
		this._startHighlightedText= t;
	},

	get startHighlightedFullText()
	{
		if( !("_startHighlightedFullText" in this) ) {
			this._startHighlightedFullText = null;
		}
		return this._startHighlightedFullText;
	},

	set startHighlightedFullText(ft)
	{
		this._startHighlightedFullText= ft;
	},

	get endAnchor()
	{
		if( !("_endAnchor" in this) ) {
			this._endAnchor = null;
		}
		return this._endAnchor;
	},

	set endAnchor(a)
	{
		this._endAnchor = a;
	},

	get endOffset()
	{
		if( !("_endOffset" in this) ) {
			this._endOffset = null;
		}
		return this._endOffset;
	},

	set endOffset(o)
	{
		this._endOffset = o;
	},

	get endHighlightedText()
	{
		if( !("_endHighlightedText" in this) ) {
			this._endHighlightedText = null;
		}
		return this._endHighlightedText;
	},

	set endHighlightedText(t)
	{
		this._endHighlightedText= t;
	},


	get endHighlightedFullText()
	{
		if( !("_endHighlightedFullText" in this) ) {
			this._endHighlightedFullText = null;
		}
		return this._endHighlightedFullText;
	},

	set endHighlightedFullText(ft)
	{
		this._endHighlightedFullText= ft;
	},

	get modifiedtime()
	{
		if( !("_modifiedtime" in this) ) {
			this._modifiedtime = 0;
		}
		return this._modifiedtime;
	},

	set modifiedtime(x)
	{
		if( this._modifiedtime == x ) {
			return;
		}

		this._modifiedtime = x;
	},

	toPersistenceObject: function()
	{
		var highlight = this;
		return {
			'ID': highlight.ID,
			'startAnchor': highlight.startAnchor,
			'startHighlightedText': highlight.startHighlightedText,
			'startHighlightedFullText' : highlight.startHighlightedFullText,
			'startOffset' : highlight.startOffset,
			'endAnchor': highlight.endAnchor,
			'endHighlightedText': highlight.endHighlightedText,
			'endHighlightedFullText' : highlight.endHighlightedFullText,
			'endOffset' : highlight.endOffset,
			'Last Modified' : highlight.modifiedtime
		};
	},

	fromPersistenceObject: function(pObj)
	{
		var highlight = new NextThought.Highlight();
		highlight.ID = pObj["ID"];
		highlight.startAnchor = pObj["startAnchor"];
		highlight.startHighlightedText = pObj["startHighlightedText"];
		highlight.startHighlightedFullText = pObj["startHighlightedFullText"];
		highlight.startOffset = pObj["startOffset"];
		highlight.endAnchor = pObj["endAnchor"];
		highlight.endHighlightedText = pObj["endHighlightedText"];
		highlight.endHighlightedFullText = pObj["endHighlightedFullText"];
		highlight.endOffset = pObj["endOffset"];
		highlight.modifiedtime = pObj["Last Modified"]*1000;

		return highlight;
	},

	save: function()
	{
		var date = new Date();
		this.modifiedtime = date.getTime();
		persistObject(username,
					  NTIHighlightType,
					  this,
					  function(obj){ },
					  function() {
						console.log('An error occurred persisting highlight');
						console.log(arguments);
					  });
	},

	remove: function(event)
	{
		deleteObject(username, NTIHighlightType, this);
	},

	makeReadOnly: function()
	{
		//TODO - Not sure what this should do yet, if anything.
		this.save=$.noop;
	},

	styleAsShared: function()
	{
		//TODO - holder for some specific style for shared highlights
	},

	show: function()
	{
		showHighlight(this);
	}

}



//NOTE: Although adding and removing a transparont background
//with a class works well on nightly webkit, it does not work
//on released Safari webkit browser. It seems to work ok on the
//device though.
function NTIShowHighlights()
{
	$(".highlight").removeClass( "highlightHidden" );
	Highlight.onhighlightsloaded = NTIShowHighlights;
}

function NTIHideHighlights()
{
	$(".highlight").addClass( "highlightHidden" );
	Highlight.onhighlightsloaded = NTIHideHighlights;
}

function NTIChangeHighlightColor( color )
{
	//Add the rule to the last sheet so it takes priority
	var sheets = document.styleSheets;
	sheets[sheets.length - 1].addRule( '#NTIContent .highlight',
									   //plain: 'background-color: ' + color );
									   //Gradient:
									   'background-image: -webkit-gradient(linear, left top, left bottom, from(white), to(' + color + '))');
}

function Highlight() {
	var self = this;

	return self;
}

function anchorNameOrNull(node) {
	if (node.name != null && node.name.trim().length > 0) {
		return node.name;
	}
	else {
		return null;
	}
}

function findLastHighlightableNodeFromChildren(node, stopNode) {
	var children = node.childNodes;
	var last = null;

	if ((isTextNode(node) && node.nodeValue.trim() != "") || isMathNode(node) || isImageNode(node)) {
		last = node;
	}

	if (children != null) {
		for(var i = 0; i < children.length; i++) {
			var child = children[i];

			if (child == stopNode) {
				return last;
			}

			if ((isTextNode(child) && child.nodeValue.trim() != "") || isMathNode(child) || isImageNode(child)) {
				last = child;
			}
			var grandchildren = child.childNodes;
			if (grandchildren != null) {
				for (var y = 0; y < grandchildren.length; y++) {
					var grandchild = grandchildren[y];
					if (grandchild == stopNode) {
						return last;
					}
					var x = findLastHighlightableNodeFromChildren(grandchild, stopNode);
					if (x) { last = x;}
				}
			}
		}
	}

	return last;
}

function findLastAnchorFromChildren(node) {
	var children = node.childNodes;
	var anchorFound = null;

	if (node.nodeName == 'A') {
		anchorFound = anchorNameOrNull(node);
	}

	if (children != null) {
		for(var i = 0; i < children.length; i++) {
			var child = children[i];
			if (child.nodeName == 'A') {
				anchorFound = anchorNameOrNull(child);
			}
			var grandchildren = child.childNodes;
			if (grandchildren != null) {
				for (var y = 0; y < grandchildren.length; y++) {
					var grandchild = grandchildren[y];
					var newAnchorFound = findLastAnchorFromChildren(grandchild);
					if (newAnchorFound != null) {
						anchorFound = newAnchorFound;
					}
				}
			}
		}
	}

	return anchorFound;
}

/*
 * given a node, climb up the DOM until we find an anchor.	If we do not find one,
 * a null is returned.	If we do find one, return the anchor's name.
 */
function ascendToAnchor(textNode) {
	var parentNode = textNode;
	if (isTextNode(textNode)) {
		textNode = textNode.parentNode;
	}

	while (parentNode != null) {
		if (parentNode.nodeName == 'A') {
			var name = anchorNameOrNull(parentNode);
			if (name != null) {
				//if we found a name, return it, otherwise allow this to continue.
				return name;
			}
		}

		//Look at all prior siblings at this level looking for an anchor
		var previousSibling = parentNode.previousSibling;
		while(previousSibling != null) {
			if (previousSibling.nodeName == 'A') {
				var name = anchorNameOrNull(previousSibling);
				if (name != null) {
					//if we found a name, return it, otherwise allow this to continue.
					return name;
				}

			}
			//look into the children of this previous node
			var anchorFromChildrenOrNull = findLastAnchorFromChildren(previousSibling);
			if (anchorFromChildrenOrNull == null) {
				previousSibling = previousSibling.previousSibling;
			}
			else {
				return anchorFromChildrenOrNull;
			}
		}
		parentNode = parentNode.parentNode;
	}

	//if we make it here, we haven't found an anchor name:
	return null;
}

function getDOMTreeId(node) {
	var parentNode = node;
	var parents = 0;
	var sibs = 0;

	while (parentNode != null) {
		parents++;

		//Look at all prior siblings at this level looking for an anchor
		var previousSibling = parentNode.previousSibling;
		while(previousSibling != null) {
			sibs++;

			previousSibling = previousSibling.previousSibling;
		}
		parentNode = parentNode.parentNode;
	}

	//if we make it here, we haven't found an anchor name:
	return "DOMTreeID:" + parents + "," + sibs;
}


function insertIntoMap(anchorName, node, textNodeMap)
{
	var list = textNodeMap[anchorName];
	if( list != null ) {
		list.push(node);
	}
	else {
		list = [node];
	}
	textNodeMap[anchorName] = list;
}

nonHighlightableElements = ['SCRIPT', 'DIV', 'OL', 'LI', 'UL', 'P', 'SPAN'];
function isHighlightable(node)
{
	for( var i = 0; i < nonHighlightableElements.length; i++ ) {
		if (nonHighlightableElements[i] == node.nodeName) {
			return false;
		}
	}

	return true;
}

function isMathNode(node)
{
	return node && $(node).hasClass( 'math' );
}

function isTextNode(node) {
	if( node.nodeValue != null ) {
		return true;
	}
	return false;
}

/*
 * Parses the DOM looking for text nodes and returns a map of
 * anchor names to node, something like Map<String, List<Node>>
 */
function mapTextToAnchors() {
	//this will contain a map of anchor names to list of text nodes
	var textNodeMap = new Object();
	var root = document.body;
	var node = root.childNodes[0];
	while(node != null) {
		if (isMathNode(node)) {
			var anchor = ascendToAnchor(node);
			insertIntoMap(anchor, node, textNodeMap);
			//console.log("NodeMapping: Found a math node with value " + node.innerText);
			//if we found a math node, we'll take everything inside and skip to the next
			while(node.nextSibling == null && node != root) {
                node = node.parentNode;
            }
            node = node.nextSibling;
			continue;
		}
		else if (isImageNode(node)) {
			var anchor = ascendToAnchor(node);
			insertIntoMap(anchor, node, textNodeMap);
			//console.log("NodeMapping: Found an image node with value " + node.innerText);
		}
		else if (isHighlightable(node) && isTextNode(node) && node.nodeValue.trim().length > 0) {
			var anchorName = ascendToAnchor(node);
			if (anchorName != null) {
				insertIntoMap(anchorName, node, textNodeMap);
				//console.log("NodeMapping: Found text node with value " + node.nodeValue);
			}
		}
		else {
			console.log("NodeMapping: Ignoring node of type " + node.nodeName + " with value: " + node.nodeValue);
		}

		//progress through next/child nodes...
		if(node.hasChildNodes()) {
			node = node.firstChild;
		}
		else {
			while(node.nextSibling == null && node != root) {
				node = node.parentNode;
			}
			node = node.nextSibling;
		}
	}
	return textNodeMap;
}

function findStartIndex(node, offset) {
	if (node.nodeName == "SPAN") {
		return 0; //who cares.
	}
	else {
		return offset;
	}
}

function findNodes(nodes, startText, fullStartingText, startOffset, endText, fullEndingText, endOffset, stopWhenNodeFound) {
	var results = [];
	var foundStartNode = false;
	var foundEndNode = false;
	if (startText == null) {
		//we've already found a start node elsewhere, just start at the beginning
		foundStartNode = true;
	}
	for (var i = 0; i < nodes.length; i++) {
		var node = nodes[i];
	    //deal with TXT nodes only here
		if (isTextNode(node)) {
			//if this node is text, see if the text matches the start
			if (!foundStartNode && node.nodeValue.substring(startOffset, startOffset + startText.length) == startText && node.nodeValue == fullStartingText) {
				//found matching text, this is the start of the stuff we want to keep
				results.push(node);
				foundStartNode = true;
				if (stopWhenNodeFound) {
					//When this flag is set, we're looking for a special case where there's just 1 node involved.
					return results;
				}
			}
			else if (!foundEndNode && foundStartNode && endText != null && (node.nodeValue.indexOf(endText) + endText.length) == endOffset && node.nodeValue == fullEndingText) {
				//already found starting node, have not seen end node yet, and this matches the end text.
				results.push(node);
				foundEndNode = true;
				//if we see this, we are done here:
				return results;
			}
			else if (foundStartNode && !foundEndNode) {
				//a text node, but we've already found the start but not the end yet
				results.push(node);
			}
		}
		else if (isImageNode(node) || isMathNode(node)) {
			var domID = getDOMTreeId(node);
			if (domID == fullStartingText) {
				foundStartNode = true;
				results.push(node);
			}
			else if ((domID == fullEndingText) && !foundEndNode) {
				foundEndNode = true;
				results.push(node);
			}
			else if (foundStartNode && !foundEndNode) {
				results.push(node);
			}
		}
		else {
			//console.log("FindNodes: Not adding node " + node.nodeName + " to list of nodes to highlight");
		}
	}
	return results;
}

function getNodesToHighlight(anchorToNodeMap, highlight) {
	//some flags so we know where we are in the list.
	var foundStartingAnchor = false;
	var foundEndingAnchor = false;

	//special case flag, identifies this as a one node only operation
	var oneNodeOnly = (highlight.endAnchor == null) ? true : false;

	//var nodePairList = [];
	var nodeList = [];

	for (var key in anchorToNodeMap) {
		//This section makes note of where we are in the list.
		var isStartingAnchor = false;
		var isEndingAnchor = false;
		if (key == highlight.startAnchor) {
			foundStartingAnchor = true;
			isStartingAnchor = true;
		}
		if (key == highlight.endAnchor) {
			foundEndingAnchor = true;
			isEndingAnchor = true;
		}

		//this section remembers importiant nodes
		if (isStartingAnchor) {
			var nodes = findNodes(anchorToNodeMap[key], highlight.startHighlightedText, highlight.startHighlightedFullText, highlight.startOffset, (highlight.startAnchor == highlight.endAnchor) ? highlight.endHighlightedText : null, highlight.endHighlightedFullText, highlight.endOffset, oneNodeOnly);
			nodeList = nodeList.concat(nodes);
		}
		else if (isEndingAnchor && highlight.endHighlightedText != null) {
			var nodes = findNodes(anchorToNodeMap[key], null, null, null, highlight.endHighlightedText, highlight.endHighlightedFullText, highlight.endOffset, oneNodeOnly);
			nodeList = nodeList.concat(nodes);
		}
		else if (isEndingAnchor && highlight.endHighlightedText == null) {
			nodeList = nodeList.concat(anchorToNodeMap[key]);
		}
		else if (foundStartingAnchor && !foundEndingAnchor) {
			//just remember all nodes in between
			nodeList = nodeList.concat(anchorToNodeMap[key]);
		}

		//This section decides when we need to quit this loop
		if (foundEndingAnchor || (foundStartingAnchor && highlight.endAnchor == null)) {
			return nodeList;
		}
	}

	//shouldn't get here:
	return nodeList;
}

function highlightMathNode(mathNode, highlightID)
{
	//mathNode.className += " highlight";
	// Add the highlight to the parent/wrapper node
	mathNode.parentNode.setAttribute("class", "highlight");
	mathNode.parentNode.className += " "+highlightID;
}

function highlightImageNode(i, highlightID)
{
	i.className += " highlight "+highlightID;
}

function createRange(startNode, startIndex, endNode, endIndex, highlightID) {
	var range = document.createRange();
	var highlightSpan = document.createElement("span");
	highlightSpan.setAttribute("class", "highlight");

	highlightSpan.className += " " + highlightID;

	range.setStart(startNode, startIndex);
	range.setEnd(endNode, endIndex);
	range.surroundContents(highlightSpan);
	success = true;
	/*
	var success = false;
	var endNodeWeAreIteratingOver = endNode;
	var currentEndIndex = endIndex;
	var currentStartNode = startNode;
	var currentStartIndex = startIndex;





	if (startNode.parentNode != null && isMathJaxSpanOrNobrNode(startNode.parentNode)) {
		currentStartNode = climbOutOfSpan(currentStartNode);
		currentStartIndex = 0;
		if (isTextNode(currentStartNode)) {
			currentStartIndex = currentStartNode.nodeValue.length;
		}
	}

	while (!success) {
		try {
			var range = document.createRange();
			var highlightSpan = document.createElement("span");
			highlightSpan.setAttribute("class", "highlight");
			range.setStart(currentStartNode, currentStartIndex);
			range.setEnd(endNodeWeAreIteratingOver, currentEndIndex);
			range.surroundContents(highlightSpan);
			success = true;
		}
		catch (err) {
			if (endNodeWeAreIteratingOver.nextSibling != null) {
				endNodeWeAreIteratingOver = endNodeWeAreIteratingOver.nextSibling;
			}
			else {
				endNodeWeAreIteratingOver = endNodeWeAreIteratingOver.parentNode;
			}
			currentEndIndex = 0; //since we are climbing out of our non-text nodes, there's no index beyond
			//allow loop
		}
	}
	 */
}

//climb upward looking for root mathjax nodes
function isMathJaxSpanOrNobrNode(node) {
	if (node.className == null) {
		//top
		return false;
	}
	else if (node.className.indexOf("mathjax") != -1 || node.nodeName == "NOBR") {
		return true;
	}

	var parent = node.parentNode;
	while (parent != null) {
		if (parent.className == null) {
			//top
			return false;
		}
		else if (parent.className.indexOf("mathjax") != -1 || node.nodeName == "NOBR") {
			return true;
		}
		parent = parent.parentNode;
	}

	return false;
}

function climbOutOfSpan(node) {
	var insideSpan = false;

	//init state
	if (node.parentNode != null && isMathJaxSpanOrNobrNode(node.parentNode)) {
		insideSpan = true;
	}

	var next = node;

	while(insideSpan) {
		//climb back and up
		if (next.previousSibling != null) {
			next = next.previousSibling;
		}
		else {
			next = next.parentNode;
		}

		if (!isMathJaxSpanOrNobrNode(next)) {
			insideSpan = false;
		}

	}

	return next;
}

function showHighlight(highlight) {
	var anchorToTextMap = mapTextToAnchors();
	//Get a list of all potential nodes we may have to highlight
	var textNodeList = getNodesToHighlight(anchorToTextMap, highlight);


	for (var i = 0; i < textNodeList.length; i++) {
		var node = textNodeList[i];

		//setup some offsets for the first and last nodes:  We only care about offsets when
		//we are dealing with the first and last pair of nodes.
		var startOffset = 0;
		var endOffset = null;
		if (i == 0 && isTextNode(node)) {
			startOffset = highlight.startOffset;
		}
		if (i == textNodeList.length -1 && isTextNode(node) && highlight.endOffset != null) {
			//last node (might be the same as the first node)
			endOffset = highlight.endOffset;
		}
		else if (isTextNode(node)){
			endOffset = node.nodeValue.length;
		}

		//highlight
		if (isTextNode(node)) {
			createRange(node, startOffset, node, endOffset, highlight.ID);
		}
		else if (isImageNode(node)) {
			 highlightImageNode(node, highlight.ID);
		}
		else if (isMathNode(node)) {
			 highlightMathNode(node, highlight.ID);
		}
	}
}

function climbToMathNode(node) {
	var topMathNode = null;

	if (isMathNode(node)) {
		topMathNode = node;
	}

	var parent = node.parentNode;
	while (parent != null) {
		if (isMathNode(parent)) {
			topMathNode = parent;
		}
		parent = parent.parentNode;
	}

	return topMathNode;
}

function digForImageNode(n) {
	if (isImageNode(n)) {
		return n;
	}

	var child = n.firstChild;
	while (child) {
		if (isImageNode(child)) {
			return child;
		}
		var next = child.nextSibling;
		if (next == null) {
			child = child.firstChild;
		}
		else {
			child = next;
		}
	}
}

function getFirstMathJaxId(node) {
	if (node.id.indexOf("MathJax-Span") != -1) {
		return node.id;
	}
	var children = node.children;
	if (children != null && children.length > 0) {
		for(var i = 0; i < children.length; i++) {
			var child = children[i];
			return getFirstMathJaxId(child);
		}
	}
	else {
		var next = node.nextSibling;
		if (next) {
			return getFirstMathJaxId(next);
		}
	}
}

function isImageNode(node) {
	if (node.nodeName == "IMG") {
		return true;
	}
	return false;
}

function getNodeTextValue(node) {
	var math = climbToMathNode(node);
	var img = digForImageNode(node);
	if (math != null) {
		//we have a math parent node
		//TODO - using the id here is fragile because changing content can break this when saved
		return getDOMTreeId(math);
	}
	else if (img != null) {
		return getDOMTreeId(img);
	}
	else if (isTextNode(node)) {
		return node.nodeValue;
	}
	else {
		//console.log("Cannot figure out the textual value of the node " + node);
		return null;
	}

}

/*
 * Takes the current selected range, and translates that into anchor/text pairs (start and end).
 * Then calls highlight and saves locally.
 */
function translateSelectAndSave() {
	var range = window.getSelection().getRangeAt(0);
	var highlight = new NextThought.Highlight();

	var startNode = range.startContainer;
	highlight.startAnchor = ascendToAnchor(startNode);
	highlight.startOffset = range.startOffset;
	var endNode = range.endContainer;
	highlight.endAnchor = ascendToAnchor(endNode);
	highlight.endOffset = range.endOffset;

	//special case when the end node is a div containing an img.
	if (endNode.nodeName == "DIV" && isImageNode(endNode.firstChild)){
		endNode = endNode.firstChild;
	}

	if (!isTextNode(endNode) && !isMathNode(endNode) && !isImageNode(endNode)) {
		var foundHighlightable = false;
		var workingNode = endNode;
		while(!foundHighlightable) {
			var previous = workingNode.previousSibling;
			if (previous) {
				workingNode = previous;
				var end = findLastHighlightableNodeFromChildren(previous, endNode);
				if (end) {
					endNode = end;
					var newAnchor = ascendToAnchor(end);
					highlight.endAnchor = newAnchor;
					if (isTextNode(end)) {
						highlight.endOffset = endNode.nodeValue.length;
					}
						foundHighlightable = true;
				}
			}
			else {
				var parent = workingNode.parentNode;
				if (parent) {
					workingNode = parent;
					var end = findLastHighlightableNodeFromChildren(parent, endNode);
					if (end) {
						endNode = end;
						var newAnchor = ascendToAnchor(end);
						highlight.endAnchor = newAnchor;
						if (isTextNode(end)) {
							highlight.endOffset = endNode.nodeValue.length;
						}
						foundHighlightable = true;
					}
				}
			}
		}
	}
	//now we have our start and end, let's see if we span anchors
	if (startNode == endNode) {
		//same anchor, this effects our snippets, there is no end snippet
		highlight.startHighlightedFullText = getNodeTextValue(startNode);
		highlight.startHighlightedText = (highlight.startHighlightedFullText != startNode.nodeValue) ? highlight.startHighlightedFullText : startNode.nodeValue.substring(range.startOffset, range.endOffset);
		highlight.endAnchor = null; //we don't need to save this.
	}
	else {
		//different anchors, we'll have 2 snippets
		highlight.startHighlightedFullText = getNodeTextValue(startNode);
		highlight.startHighlightedText = (highlight.startHighlightedFullText != startNode.nodeValue) ? highlight.startHighlightedFullText : startNode.nodeValue.substring(range.startOffset);
		highlight.endHighlightedFullText = getNodeTextValue(endNode);
		if(range.endOffset != 0 && endNode.nodeValue != null) {
			highlight.endHighlightedText = (highlight.endHighlightedFullText != endNode.nodeValue) ? highlight.endHighlightedFullText : endNode.nodeValue.substring(0, range.endOffset);
		}
		else {
			highlight.endHighlightedText = highlight.endHighlightedFullText;
		}
	}

	highlight.save();
	highlight.show();

}

/*
 * End code for highlighting
 */


/*
 * functions to load data from various storage locations
 */


function loadDataToLocal(pageKey, key, data) {
 	localStorage.setItem(pageKey + '/' + key, data);
}

function removeDataFromLocal(pageKey, key) {
 	localStorage.removeItem(pageKey + '/' + key);
}

function loadLocalData() {
 	//TODO
}


function syncData (type,onsynccomplete) {



	getObjects(username, type, null, null,
		   function(result)
		   {
			   var serverPageLastModified = result['Last Modified']; //seconds since epoc

			   var serverDataForPage = null;
			   if( result['Items'] ) {
					serverDataForPage = result['Items'];
			   }
			   else {
			   		serverDataForPage = result;
			   }
			   var localDataForPage = objectsFromLocalStorage(type);

			   if(!localDataForPage){
				   localDataForPage={'Last Modified':0};
			   }

			   var localPageLastModified = localDataForPage['Last Modified']; // seconds since epoc

			   //We match things by id so we better be consistent

			   var allIds = [];
			   var idsProcessed = {};

			   for(id in serverDataForPage)
			   {
				   allIds.push(id);
			   }
			   for(id in localDataForPage)
			   {
				   allIds.push(id);
			   }

			   for(var i = 0; i < allIds.length; i++)
			   {
				   var id = allIds[i];
				   if(idsProcessed[id] || id == 'Last Modified')
				   {
					   continue;
				   }

				   var localObj = localDataForPage[id];
				   var serverObj = serverDataForPage[id];

				   //We have the object in both local and server
				   //Keep whatever was modified last
				   if(localObj && serverObj)
				   {
					   if(localObj['Last Modified'] > serverObj['Last Modified'])
					   {
						   persistObject(username, type, localObj, $.noop, function(){console.log('Error syncing '+localObj+' to server');});
					   }
					   else
					   {
						   localDataForPage[id]=serverObj;
					   }
				   }
				   else if(serverObj && !localObj)
				   {
					   if(serverPageLastModified >= localPageLastModified)
					   {
						   localDataForPage[id]=serverObj;
					   }
				   }
				   else if(localObj && !serverObj)
				   {
					   if(localPageLastModified < serverPageLastModified)
					   {
						   delete localDataForPage[id];
					   }
				   }

				   idsProcessed[id]=true;
			   }

			   persistObjectsDictionaryToLocalStorage(type, localDataForPage);

			   onsynccomplete(localDataForPage);

		   },
		   function(){
			   //TODO: check that we only ignore 404s here
		   });

}

function syncAndLoadNotes()
{

	var create = Note.prototype.fromPersistenceObject;
	syncData(NTINoteType,
			 function(localNotesForPage)
			 {
				 for(id in localNotesForPage)
				 {
					 if(id == 'Last Modified')
					 {
						 continue;
					 }
					 var note = create(localNotesForPage[id]);

				 }
			 });


	console.log('Loading notes for '+friendsList);
	for(var i=0;i<friendsList.length;i++)
	{
		loadSharedObjects(friendsList[i], NTINoteType, create);
	}
}

function syncAndLoadHighlights()
{

	var create = NextThought.Highlight.prototype.fromPersistenceObject;
	syncData(NTIHighlightType,
			 function(localHighlightsForPage)
			 {
				for(id in localHighlightsForPage)
				{
					if(id == 'Last Modified')
					{
						continue;
					}
			 		var highlight = create(localHighlightsForPage[id]);
					highlight.show();
				}
			 });


	console.log('Loading highlights for '+friendsList);
	for(var i=0;i<friendsList.length;i++)
	{
		loadSharedObjects(friendsList[i], NTIHighlightType, create);
	}
}


function NTIShowHighlightsFromArray(highlights)
{
//	alert(JSON.stringify(highlights));
	for(var i=0; i<highlights.length; i++){
//		alert(JSON.stringify(highlights[i]));
		var highlight = NextThought.Highlight.prototype.fromPersistenceObject(highlights[i]);
		console.log(highlight);
//		alert(JSON.stringify(highlight.toPersistenceObject()));
		highlight.show();
	}
	return true;
}

"NTIJSInjection_DONE";
