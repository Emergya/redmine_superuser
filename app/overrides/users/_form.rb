Deface::Override.new :virtual_path  => 'users/_form',
                     :name          => 'add-admin-superuser-form',
                     :original		=> 'e60a4fa50dfadff1543026068000af0103515325',
                     :replace		=> "erb[loud]:contains('admin')",
                     :partial       => 'users/user_form_superuser'
