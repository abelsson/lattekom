<%@ page language='java' import='nu.dll.lyskom.*, com.oreilly.servlet.multipart.*, java.util.*,
				 java.net.*, java.io.*, java.text.*,java.util.regex.*' %>
<%@ include file='kom.jsp' %>
<%
	Session lyskom = (Session) session.getAttribute("lyskom");
	int conferenceNumber = ((Integer) request.getAttribute("conferenceNumber")).intValue();
	int textNumber = ((Integer) request.getAttribute("text")).intValue();
        out.println("<a name=\"text" + textNumber + "\"></a>");
%>
	<p class="boxed">
<%
	Text text = null;
	try {
	    text = lyskom.getText(textNumber);
	} catch (RpcFailure ex1) {
	    if (ex1.getError() == Rpc.E_no_such_text) {
		out.println("<p class=\"statusError\">Text " + 
		    textNumber + " finns inte.</p>");
		out.println("</p>");
		return;
	    }
	}
	List viewedTexts = (List) request.getAttribute("viewedTexts");
	if (viewedTexts == null) {
	    viewedTexts = new LinkedList();
	    request.setAttribute("viewedTexts", viewedTexts);
	}
	viewedTexts.add(new Integer(text.getNo()));

	boolean noComments = text.getAuxItems(AuxItem.tagNoComments).size() > 0;
	String contentType = text.getContentType();
	String charset = text.getCharset();
	if (charset == null) charset = "iso-8859-1";
	if (charset.equals("us-ascii")) charset = "iso-8859-1"; // some broken elisp clients lie...
	if (contentType.equals("x-kom/text")) contentType = "text/x-kom-basic";
%>
        <%= jsTitle(serverShort(lyskom) + ": text " + text.getNo() + " av " + 
		lookupName(lyskom, lyskom.getTextStat(text.getNo()).getAuthor()) +
		": " + new String(text.getSubject())) %>
	<tt>Text nummer <%= textLink(request, lyskom, text.getNo(), false) %> av
<%
	List auxMxAuthor = Arrays.asList(text.getAuxData(AuxItem.tagMxAuthor));
	List auxMxFrom = Arrays.asList(text.getAuxData(AuxItem.tagMxFrom));
	List auxMxTo = Arrays.asList(text.getAuxData(AuxItem.tagMxTo));
	List auxMxCc = Arrays.asList(text.getAuxData(AuxItem.tagMxCc));
	List auxMxDate = Arrays.asList(text.getAuxData(AuxItem.tagMxDate));
	List auxMxMimePartIn = Arrays.asList(text.getAuxData(AuxItem.tagMxMimePartIn));
	if (auxMxAuthor.size() > 0) {
	     out.print(htmlize(((Hollerith) auxMxAuthor.get(0)).getContentString()));
	}
	if (auxMxFrom.size() > 0) {
	    String email = ((Hollerith) auxMxFrom.get(0)).getContentString();
	    out.print(" &lt;<a href=\"mailto:");
	    out.print(htmlize(email));
	    out.print("\">");
	    out.print(htmlize(email));
	    out.println("</a>>");
	}
	if (auxMxAuthor.size() == 0 && auxMxFrom.size() == 0) {
	    out.println(lookupName(lyskom, text.getAuthor(), true));
	}
	
%><br>
	textkommandon: 
        <a title="Markera text" href="<%=myURI(request)%>?mark=<%=text.getNo()%>">M</a>
        <a title="Avmarkera text" href="<%=myURI(request)%>?unmark=<%=text.getNo()%>">A</a>
        <a title="Personligt svar" href="<%=myURI(request)%>?privateReply=<%=text.getNo()%>">p</a>
	<% if (text.getAuthor() == lyskom.getMyPerson().getNo()) { %>
        <a title="Fotnotera" href="<%=myURI(request)%>?footnoteTo=<%=text.getNo()%>&dispatchToComposer">F</a>
        <% }
	   if (text.getCommented() != null && text.getCommented().length > 0) { %>
        <a title="�terse urinl�gg" href="<%=myURI(request)%>?reviewOriginal=<%=text.getNo()%>">�u</a>
	<% } %>
	<br/>
	Skapad <%= df.format(text.getCreationTime()) %><br/>
<%
	int[] commented = text.getCommented();
	int[] comments = text.getComments();
	int[] footnoted = text.getFootnoted();
	int[] footnotes = text.getFootnotes();
	for (int i=0; i < commented.length; i++) {
%>
	Kommentar till text <%= textLink(request, lyskom, commented[i]) %><br/>
<%
	}
	for (int i=0; i < footnoted.length; i++) {
%>
	Fotnot till text <%= textLink(request, lyskom, footnoted[i]) %><br/>
<%
	}


	int[] recipients = text.getRecipients();
	int[] ccRecipients = text.getCcRecipients();
	for (int i=0; i < recipients.length; i++) {
%>
	Mottagare: <%= lookupName(lyskom, recipients[i], true) %><br/>
<%
	}
	for (int i=0; i < ccRecipients.length; i++) {
%>
	Extra kopia: <%= lookupName(lyskom, ccRecipients[i], true) %><br/>
<%
	}

%>
	�rende: <%= new String(text.getSubject()) %><br/>
	<hr noshade width="95%" align="left" />
<%
	if (contentType.equals("text/x-kom-basic") || contentType.equals("text/plain")) {
%>
        <pre class="text"><%= htmlize(new String(text.getBody(), charset)) %></pre>
<%
	} else {
%>
	<p class="statusError">Varning: textens datatyp ("<%=contentType%>") kan inte visas.<br/>
	<a href="/lyskom/rawtext.jsp?text=<%=text.getNo()%>">Klicka h�r</a> f�r att visa r�data.</p>
<%
	}
%>
	<hr noshade width="95%" align="left" />
<%
	List fastReplies = text.getAuxItems(AuxItem.tagFastReply);
	for (Iterator i = fastReplies.iterator(); i.hasNext();) {
	    AuxItem item = (AuxItem) i.next();
	    out.print("<span title=\"Anm�rkning skapad ");
	    out.print(df.format(item.getCreatedAt().getTime()));
	    out.print("\">");
	    if (item.getCreator() == text.getAuthor()) {
		out.print("<b>Anm�rkning av f�rfattaren:</b> ");
	    } else {
		out.print("<b>Anm�rkning av ");
		out.print(lookupName(lyskom, item.getCreator(), true));
		out.print(":</b> ");
	    }
	    out.print(htmlize(item.getDataString()));
	    out.println("</span></br>");
	}
	Set attachmentTexts = new HashSet();
	for (Iterator i = auxMxMimePartIn.iterator(); i.hasNext();) {
	    attachmentTexts.add(new Integer(((KomToken) i.next()).intValue()));
	}
	for (int i=0; i < comments.length; i++) {
	    if (attachmentTexts.contains(new Integer(comments[i]))) {
		TextStat ts = lyskom.getTextStat(comments[i]);
%>
		Bilaga av typen <%= ts.getContentType() %> i <%= textLink(request, lyskom, comments[i], false) %>
		 (<a href="/lyskom/rawtext.jsp?text=<%=comments[i]%>">visa</a>)<br/>
<%
	    } else {
%>
		Kommentar i text <%= textLink(request, lyskom, comments[i]) %><br/>
<%
	    }
 	}
%>	<%= comments.length > 0 ? "<br/>" : "" %>
<%
	for (int i=0; i < footnotes.length; i++) {
%>
	Fotnot i text <%= textLink(request, lyskom, footnotes[i]) %><br/>
<%
	}
%>	<%= footnotes.length > 0 ? "<br/>" : "" %>
	</tt>
<%
    if (conferenceNumber > 0 && textNumber > 0 && request.getParameter("comment") == null) {
%>
	<a href="<%= myURI(request) %>?conference=<%=conferenceNumber%>&markAsRead=<%=textNumber%>">
	  L�smarkera denna text (och l�s n�sta).</a><br/>
<%
    }
    if (textNumber > 0) {
%>
	<a <%= (noComments ? "onClick=\"return confirm('Textf�rfattaren vill helst inte ha n�gra kommentarer till denna text. Vill du forts�tta �nd�?');\"" : "") %> href="<%= myURI(request) %>?<%= conferenceNumber > 0 ? "conference="+conferenceNumber : ""%>&markAsRead=<%=textNumber%>&text=<%=textNumber%>&comment=<%=textNumber%>">
	  Kommentera (och l�smarkera) denna text.</a><br/>
<%
    }
%>
	</p>
<%
    out.flush();
    RequestDispatcher d = getServletContext().getRequestDispatcher("/lyskom/text.jsp");
    for (int i=0; i < footnotes.length; i++) {
	request.setAttribute("text", new Integer(footnotes[i]));
	d.include(request, response);
    }
%>