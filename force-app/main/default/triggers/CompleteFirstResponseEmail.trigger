trigger CompleteFirstResponseEmail on EmailMessage (after insert)
{
    CompleteFirstResponseEmailHandler c = new CompleteFirstResponseEmailHandler(Trigger.new);
    
}