# Customer Experience installing a Power Platform hosted Industry Link 

Take the following steps to install the Power Platform Industry Link template from AppSource. 

## Step 1: Install from AppSource 

Install the Industry Link into the environment. 

1. Go to the Industry Link in AppSource and select **Install**.

    ![The Industry Link AppSource offer](images/powerPlatformCustomerExperience/InstallFromAppSource1.png)

2. Confirm your details and select **Install**.

    ![Confirm the installation of the Industry Link](./images/powerPlatformCustomerExperience/InstallFromAppSource2.png)

3. Select the environment that you want to install the solution template into.

    ![Select an environment](./images/powerPlatformCustomerExperience/InstallFromAppSource3.png "Select an environment")

4. Agree to the Terms and Privacy Statements by checking the boxes.
5. Select **Install**. You'll be taken to a screen where you can view the installation status. After the installation is complete, the status shows as *Installed*.

## Step 2: Set flow connections 

1. Open the Industry Link solution by selecting the **ContosoIndustryLink** in the **Solutions** tab.

    ![Open Industry Link solution](./images/powerPlatformCustomerExperience/SetFlowConnections1.png)

2. Go to **Cloud Flows**. There are two cloud flows that require editing:
    - **GetDataFromCustomConnector**
    - **IngestIntoDataverse**
3. Edit the *IngestIntoDataverse* flow:
    1. Select the *IngestIntoDataverse* flow.

        ![Select on the IngestIntoDataverse flow](./images/powerPlatformCustomerExperience/SetFlowConnections2.png)

    2. Select **Edit** -> **Edit with designer** in the top-left corner.
   
        ![Edit flow](./images/powerPlatformCustomerExperience/SetFlowConnections3.png)

    3. Select **Sign In** on the Microsoft Dataverse connection.
   
        ![Select Sign In](./images/powerPlatformCustomerExperience/SetFlowConnections4.png)

    4. Enter your credentials or pick an existing account to authenticate with Dataverse. If a connection already exists, it will automatically connect to it when you selected Sign In.
    5. Select **Continue**.

        ![Sign into Dataverse connector](./images/powerPlatformCustomerExperience/SetFlowConnections5.png)

    6. Select **Save** in the top toolbar.
    7. Select the back arrow to return to the solution.
4. Edit the *GetDataFromCustomConnector*:
    1. Select the *GetDataFromCustomConnector* flow.

        ![Select on the GetDataFromCustomConnector flow](./images/powerPlatformCustomerExperience/SetFlowConnections6.png)

    2. Select **Edit** -> **Edit with designer** in the top-left corner.

        ![Edit flow](./images/powerPlatformCustomerExperience/SetFlowConnections3.png)

    3. Select **+ New connection reference** to create a connection to the *ContosoIndustryLinkAPI* custom connector.

        ![Select create new connection reference](./images/powerPlatformCustomerExperience/SetFlowConnections7.png)

    4. Enter the connection name and credentials to authenticate with the custom connector.
    5. Select **Create**.
    6. Select **Save** in the top toolbar.
    7. Select the back arrow to return to the solution.

## Step 3: Set Cloud Flows to On 

In the Industry Link (*ContosoIndustryLink*) solution, verify that the two cloud flows are set to the on status. If they aren't, turn them on.

1. Select the *IngestIntoDataverse* cloud flow. Select **Turn on** in the top toolbar.

    ![Turn on IngestIntoDataverse flow](./images/powerPlatformCustomerExperience/SetCloudFlowToOn1.png)

2. Select the *GetDataFromCustomConnector* cloud flow. Select **Turn on** in the top toolbar.

    ![Turn on GetDataFromCustomConnector flow](./images/powerPlatformCustomerExperience/SetCloudFlowToOn2.png)
 