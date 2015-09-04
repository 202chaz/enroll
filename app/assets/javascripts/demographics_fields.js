function applyListeners() {

    $("input[name='dependent[us_citizen]']").change(function () {
        if ($(this).val() == 'true') {
            $('#naturalized_citizen_container').show();
            $('#dependent_naturalized_citizen_true').attr('required');
            $('#dependent_naturalized_citizen_false').attr('required');
            $('#immigration_status_container').hide();
            $('#immigration_fields_container').hide();
        } else {
            $('#dependent_naturalized_citizen_true').removeAttr('required');
            $('#dependent_naturalized_citizen_false').removeAttr('required');
            $('#naturalized_citizen_container').hide();
            $('#vlp_document_id_container').hide();
            $('#immigration_status_container').show();
        }
    });

    $("input[name='person[eligible_immigration_status]']").change(function () {
            if ($(this).val() == 'true') {
                $('#immigration_fields_container').show();
                $("input[name='person[naturalized_citizen]']").attr('checked', false)
            } else {
                $('#immigration_fields_container').hide();
            }
        }
    );

    $("input[name='dependent[eligible_immigration_status]']").change(function () {
            if ($(this).val() == 'true') {
                $('#immigration_fields_container').show();
                $("input[name='dependent[naturalized_citizen]']").attr('checked', false)
            } else {
                $('#immigration_fields_container').hide();
            }
        }
    );

    $("#naturalization_doc_type").change(function () {
        if ($(this).val() == 'Certificate of Citizenship') {
            $('#citizenship_cert_container').show();
            $('#naturalization_cert_container').hide();
        }
        else if ($(this).val() == 'Naturalization Certificate') {
            $('#naturalization_cert_container').show();
            $('#citizenship_cert_container').hide();
        }
    });


    $("#immigration_doc_type").change(function () {
        switch ($(this).val()) {
            case "I-327 (Reentry Permit)":
                showOnly("immigration_i_327_fields_container");
                break;
            case "I-551 (Permanent Resident Card)":
                showOnly("immigration_i_551_fields_container");
                break;
            case "I-571 (Refugee Travel Document)":
                showOnly("immigration_i_571_fields_container");
                break;
            case "I-766 (Employment Authorization Card)":
                showOnly("immigration_i_766_fields_container");
                break;
            case "Certificate of Citizenship":
                showOnly("immigration_citizenship_cert_container");
                break;
            case "Naturalization Certificate":
                showOnly("immigration_naturalization_cert_container");
                break;
            case "Machine Readable Immigrant Visa (with Temporary I-551 Language)":
                showOnly("immigration_temporary_i_551_stamp_fields_container");
                break;
            case "Temporary I-551 Stamp (on passport or I-94)":
                showOnly("immigration_temporary_i_551_stamp_fields_container");
                break;
            case "I-94 (Arrival/Departure Record)":
                showOnly("immigration_i_94_fields_container");
                break;
            case "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport":
                showOnly("immigration_i_94_2_fields_container");
                break;
            case "Unexpired Foreign Passport":
                showOnly("immigration_unexpired_foreign_passport_fields_container");
                break;
            case "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)":
                showOnly("immigration_temporary_i_20_stamp_fields_container");
                break;
            case "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)":
                showOnly("immigration_DS_2019_fields_container");
                break;
            case "Other (With Alien Number)":
                showOnly("immigration_other_with_alien_number_fields_container");
                break;
            case "Other (With I-94 Number)":
                showOnly("immigration_other_with_i94_fields_container");
                break;
        }
    });

    function showOnly(selected) {
        var doc_types = ["immigration_citizenship_cert_container", "immigration_naturalization_cert_container",
            "immigration_i_327_fields_container", "immigration_i_551_fields_container", "immigration_i_571_fields_container",
            "immigration_i_766_fields_container", "immigration_i_566_fields_container",
            "immigration_temporary_i_551_stamp_fields_container", "immigration_i_94_fields_container",
            "immigration_i_94_in_unexpired_foreign_passport_fields_container", "immigration_unexpired_foreign_passport_fields_container",
            "immigration_temporary_i_20_stamp_fields_container", "immigration_DS_2019_fields_container",
            "immigration_other_with_alien_number_fields_container", "immigration_other_with_i94_fields_container"]

        for (index = 0; index < doc_types.length; index++) {
            $('#' + doc_types[index]).hide();
        }
        $('#' + selected).show();
    }

    $("input[name='dependent[naturalized_citizen]']").change(function () {

        if ($(this).val() == 'true') {
            $('#vlp_document_id_container').show();
        } else {
            $('#vlp_document_id_container').hide();
        }
    });

    $("input[name='person[us_citizen]']").change(function () {
        if ($(this).val() == 'true') {
            $('#naturalized_citizen_container').show();
            $('#person_naturalized_citizen_true').attr('required');
            $('#person_naturalized_citizen_false').attr('required');
            $('#immigration_status_container').hide();
            $('#immigration_fields_container').hide();
        } else {
            $('#person_naturalized_citizen_true').removeAttr('required');
            $('#person_naturalized_citizen_false').removeAttr('required');
            $('#naturalized_citizen_container').hide();
            $('#vlp_document_id_container').hide();
            $('#immigration_status_container').show();
        }
    });


    $("input[name='person[naturalized_citizen]']").change(function () {
        if ($(this).val() == 'true') {
            $('#vlp_document_id_container').show();
            $("input[name='person[eligible_immigration_status]']").attr('checked', false)
        } else {
            $('#vlp_document_id_container').hide();
        }
    });

    $('#person_indian_tribe_member').change(function () {
        if ($(this).is(':checked')) {
            $('#tribal_container').show();
        }
        else {
            $('#tribal_container').hide();
        }
    });

    $('#dependent_indian_tribe_member').change(function () {
        show_or_hide_tribal_id();
    });
    show_or_hide_tribal_id();
    function show_or_hide_tribal_id() {
        if ($("#dependent_indian_tribe_member").is(':checked')) {
            $('#tribal_container').show();
        }
        else {
            $('#tribal_container').hide();
        }
    }
}


$(function () {
    applyListeners();
});