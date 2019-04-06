FROM vmware/photon2

LABEL authors="renoufa@vmware.com,jaker@vmware.com"

# Set terminal. If we don't do this, weird readline things happen.
ENV TERM linux
RUN echo "/usr/bin/pwsh" >> /etc/shells && \
    echo "/bin/pwsh" >> /etc/shells

# Install PowerShell and unzip on Photon
RUN tdnf install -y powershell-6.0.1 unzip

# Set working directory so stuff doesn't end up in /
WORKDIR /root

# Install PackageManagement and PowerShellGet
# This is temporary until it is included in the PowerShell Core package for Photon
RUN curl -J -L https://www.powershellgallery.com/api/v2/package/PackageManagement/1.2.2 -o PackageManagement && \
    unzip PackageManagement -d /usr/lib/powershell/Modules/PackageManagement && \
    rm -f PackageManagement

RUN curl -J -L https://www.powershellgallery.com/api/v2/package/PowerShellGet/2.0.1 -o PowerShellGet && \
    unzip PowerShellGet -d /usr/lib/powershell/Modules/PowerShellGet && \
    rm -f PowerShellGet

# Workaround for https://github.com/vmware/photon/issues/752
RUN mkdir -p /usr/lib/powershell/ref/ && ln -s /usr/lib/powershell/*.dll /usr/lib/powershell/ref/

# Install VMware modules from PSGallery
SHELL [ "pwsh", "-command" ]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
RUN Install-Module VMware.PowerCLI,PowerNSX,PowervRA, Pester

# On by default to suppress nagging. Set to $false if you don't want to help us make PowerCLI better.
# TODO: Investigate why we can't set this to either true or false.
# RUN Set-PowerCLIConfiguration -ParticipateInCeip $true -Confirm:$false

# Add the PowerCLI Example Scripts and Modules
# using ZIP instead of a git pull to save at least 100MB
SHELL [ "bash", "-c"]
RUN mkdir -p /var/opt/VMware/PowerCLI/ && echo '<Settings><Setting Name="ParticipateInCEIP" Value="False" /></Settings>' > /var/opt/VMware/PowerCLI/PowerCLI_Settings.xml
RUN curl -o ./PowerCLI-Example-Scripts.zip -J -L https://github.com/vmware/PowerCLI-Example-Scripts/archive/master.zip && \
    unzip PowerCLI-Example-Scripts.zip && \
    rm -f PowerCLI-Example-Scripts.zip && \
    mv ./PowerCLI-Example-Scripts-master ./PowerCLI-Example-Scripts && \
    mv ./PowerCLI-Example-Scripts/Modules/* /usr/lib/powershell/Modules/

# Final clean up
RUN tdnf erase -y unzip && \
    tdnf clean all

CMD ["/bin/pwsh"]
