trigger CaseVisibilityDefaults on ContentDocumentLink (before insert) {
    for (ContentDocumentLink r : Trigger.New)
    {
        if (((String)r.LinkedEntityId).startsWith('500'))
        {
            r.Visibility = 'AllUsers';
        }
    }
}