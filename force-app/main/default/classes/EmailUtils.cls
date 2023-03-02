/**
 * Developed by Doug Ayers
 */
public class EmailUtils {

    /**
     * Builds a map of Attachment objects copying values from the Files attached to the InboundEmail argument.
     * The map keys are the attachment header 'Content-ID' values.
     * The map values are unsaved Attachment records with data copied from the email.
     *
     * Use of Content-ID header is inspired by http://simplyforce.blogspot.com/2014/08/handling-inline-images-in-salesforce.html
     * so that Email2CaseHandler can replace image sources in the html body with links to actual attachments
     * so that the images render when viewing the HTML version of this email message.
     *
     * No database changes are made, you must save the Attachments.
     */
    public static Map<String, Attachment> buildAttachments( Messaging.InboundEmail email, ID parentId ) {

        Map<String, Attachment> attachmentsMap = new Map<String, Attachment>();

        // if attachment does not have Content-ID header
        // then we'll use this to generate a unique map key instead
        Integer noHeaderCount = 0;

        if ( email.binaryAttachments != null ) {

            for ( Messaging.InboundEmail.BinaryAttachment binaryAttachment : email.binaryAttachments ) {

                String contentId = getHeaderValue( binaryAttachment.headers, 'Content-ID' );

                if ( String.isBlank( contentId ) ) {
                    contentId = 'no-content-id-header-' + noHeaderCount++;
                }

                attachmentsMap.put( contentId, new Attachment(
                    name = binaryAttachment.fileName,
                    body = binaryAttachment.body,
                    contentType = binaryAttachment.mimeTypeSubType,
                    parentId = parentId
                ));

            }

        }

        if ( email.textAttachments != null ) {

            for ( Messaging.InboundEmail.TextAttachment textAttachment : email.textAttachments ) {

                String contentId = getHeaderValue( textAttachment.headers, 'Content-ID' );

                if ( String.isBlank( contentId ) ) {
                    contentId = 'no-content-id-header-' + noHeaderCount++;
                }

                attachmentsMap.put( contentId, new Attachment(
                    name = textAttachment.fileName,
                    body = Blob.valueOf( textAttachment.body ),
                    contentType = textAttachment.mimeTypeSubType,
                    parentId = parentId
                ));

            }

        }

        return attachmentsMap;
    }

    /**
     * Builds a new EmailMessage object copying values from the InboundEmail argument.
     * Sets the RelatedToId and/or ParentId value as appropriate.
     *
     * No database changes are made, you must save the EmailMessage.
     */
    /*public static EmailMessage buildEmailMessage( Messaging.InboundEmail email, ID relatedToId ) {

        // for really long emails need to truncate text
        Integer maxLengthPlainTextBody = EmailMessage.TextBody.getDescribe().getLength();
        Integer maxLengthHtmlBody = EmailMessage.HtmlBody.getDescribe().getLength();
        Integer maxLengthSubject = EmailMessage.Subject.getDescribe().getLength();

        String plainTextBody = ( String.isBlank( email.plainTextBody ) ? '' : email.plainTextBody.abbreviate( maxLengthPlainTextBody ) );
        String htmlBody = ( String.isBlank( email.htmlBody ) ? '' : email.htmlBody.abbreviate( maxLengthHtmlBody ) );
        String subject = ( String.isBlank( email.subject ) ? '' : email.subject.abbreviate( maxLengthSubject ) );

        EmailMessage message = new EmailMessage(
            textBody = plainTextBody,
            htmlBody = htmlBody,
            subject = subject,
            fromName = email.fromName,
            fromAddress = email.fromAddress,
            incoming = true
        );

        // check if enhanced email feature is enabled
        // if yes then the 'RelatedToId' field exists, otherwise it doesn't
        // https://help.salesforce.com/apex/HTViewHelpDoc?id=enable_enhanced_email.htm&language=en_US
        Map<String, Schema.SObjectField> fieldsMap = EmailMessage.sObjectType.getDescribe().fields.getMap();
        if ( fieldsMap.containsKey( 'RelatedToId' ) ) {
            // use dynamic put method because can't compile if field doesn't actually exist for dot notation
            message.put( 'RelatedToId', relatedToId );
        }

        // check if the relate to id is for a case
        // if yes then populate the 'ParentId' (precursor to Enhanced Email feature)
        String caseKeyPrefix = Case.sObjectType.getDescribe().getKeyPrefix();
        String relatedToIdPrefix = relatedToId.getSobjectType().getDescribe().getKeyPrefix();
        if ( caseKeyPrefix == relatedToIdPrefix ) {
            message.parentId = relatedToId;
        }

        if ( email.headers != null && email.headers.size() > 0 ) {
            message.headers = toString( email.headers );
        }

        if ( email.toAddresses != null && email.toAddresses.size() > 0 ) {
            message.toAddress = String.join( email.toAddresses, ';' );
        }

        if ( email.ccAddresses != null && email.ccAddresses.size() > 0 ) {
            message.ccAddress = String.join( email.ccAddresses, ';' );
        }

        return message;
    }*/

    private static String getHeaderValue( List<Messaging.InboundEmail.Header> headers, String name ) {

        String value = null;

        if ( headers != null ) {
            for ( Messaging.InboundEmail.Header header : headers ) {
                if ( header.name == name ) {
                    value = header.value;
                    break;
                }
            }
        }

        return value;
    }

    /*private static String toString( List<Messaging.InboundEmail.Header> headers ) {

        String text = '';

        if ( headers != null ) {
            for ( Messaging.InboundEmail.Header header : headers ) {
                text += header.name + '=' + header.value + '\n';
            }
        }

        return text;
    }*/

}