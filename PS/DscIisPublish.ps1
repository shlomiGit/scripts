Configuration dscTestConfig {

    # Import the module that contains the resources we're using.
    Import-DscResource -ModuleName PsDesiredStateConfiguration

    # The Node statement specifies which targets this configuration will be applied to.
    Node 'localhost' {

        # The first resource block ensures that the Web-Server (IIS) feature is enabled.
        #WindowsFeature WebServer {
        #    Ensure = "Present"
        #    Name   = "Web-Server"
        #}

        # The second resource block ensures that the website content copied to the website root folder.
        File WebsiteContent {
            Ensure = 'Present'
            SourcePath = 'C:\Users\Shlomi\AppData\Local\Temp\example.txt'
            DestinationPath = 'c:\inetpub\wwwroot'
        }
    }
}
