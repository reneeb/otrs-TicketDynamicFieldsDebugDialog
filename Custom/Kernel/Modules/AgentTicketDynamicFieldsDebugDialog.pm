# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketDynamicFieldsDebugDialog;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::Output::HTML::Layout
    Kernel::System::Ticket
    Kernel::System::Web::Request
    Kernel::System::DynamicField
    Kernel::System::DynamicField::Backend
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $TicketID = $ParamObject->GetParam( Param => 'TicketID' );

    # check needed stuff
    if ( !$TicketID ) {
        return $LayoutObject->ErrorScreen(
            Message => 'No TicketID is given!',
            Comment => 'Please contact the admin.',
        );
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $Self->{TicketID},
        DynamicFields => 1,
    );

    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldList(
        Valid      => 1,
        ResultType => 'HASH',
        ObjectType => 'Ticket',
    );

    # set dynamic fields for Ticket object type
    DYNAMICFIELDID:
    for my $DynamicFieldID ( sort keys %{$DynamicFieldList} ) {
        next DYNAMICFIELDID if !$DynamicFieldID;
        next DYNAMICFIELDID if !$DynamicFieldList->{$DynamicFieldID};

        my $Key = $DynamicFieldList->{$DynamicFieldID};

        if ( $Ticket{"DynamicField_$Key"} ) {

            # get dynamic field config
            my $DynamicFieldGet = $DynamicFieldObject->DynamicFieldGet(
                ID => $DynamicFieldID,
            );

            my $Data = $BackendObject->DisplayValueRender(
                DynamicFieldConfig => $DynamicFieldGet,
                HTMLOutput         => 1,
                LayoutObject       => $LayoutObject,
                Value              => $Ticket{"DynamicField_$Key"},
            );

            $Data->{Name}  = $Key;
            $Data->{Label} = $DynamicFieldGet->{Label};

            $LayoutObject->Block(
                Name => "DynamicField",
                Data => $Data,
            );
        }
    }

    # get output back
    my $Output = $LayoutObject->Header(
        Type  => 'Small',
        Value => $Ticket{TicketNumber},
    );

    $Output .= $LayoutObject->Output(
        TemplateFile => $Self->{Action},
        Data         => {
            %Ticket,
            %Param,
        },
    );

    $Output .= $LayoutObject->Footer(
        Type => 'Small',
    );

    return $Output;
}

1;
