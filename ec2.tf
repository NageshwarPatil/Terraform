provider "aws" {
  region                  = "ap-south-1"

  profile                 = "Akshay"
}


resource "aws_instance" "TerraLinux1" {
  ami           = "ami-0447a12f28fddb066"
availability_zone ="ap-south-1a"
  instance_type = "t2.micro"
  security_groups=["launch-wizard-4"]
  key_name="ForTera"

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key= file("C:/Users/Nmp/Downloads/ForTera.pem")
    host     = aws_instance.TerraLinux1.public_ip
  }




provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
      
    ]
  }

  tags={
      Name="TeraLinux950"
 
     }
}



output myosip{

value=aws_instance.TerraLinux1.public_ip
}


resource "null_resource" "nulllocal"{
provisioner "local-exec"{

command="echo  ${aws_instance.TerraLinux1.public_ip} > publicip.txt"
}

}










resource "aws_ebs_volume" "EbsTerra" {
  availability_zone = "ap-south-1a"
  size              = 2

  tags = {
    Name = "EbsTerra"
  }
}




resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.EbsTerra.id}"
  instance_id = "${aws_instance.TerraLinux1.id}"
  force_detach=true
}


resource "null_resource" "nullRemote6"{

depends_on = [
       aws_volume_attachment.ebs_att,
  ]

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key= file("C:/Users/Nmp/Downloads/ForTera.pem")
    host     = aws_instance.TerraLinux1.public_ip
  }

provisioner "remote-exec" {




    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
       "sudo rm -rf /var/www/html",
      "sudo git clone https://github.com/NageshwarPatil/Terraform.git /var/www/html/",
    ]
  }

}



/*

resource "null_resource" "nulllocal5"{

depends_on = [
       null_resource.nullRemote6,
  ]

provisioner "local-exec"{

command="start chrome ${aws_instance.TerraLinux1.public_ip}"
}
}
*/

# Variable Declaration For bucket
variable "Unique_Bucket_Name"{
  type = string
  default = "forterra950"
}



 #AWS S3 Bucket Creation
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.Unique_Bucket_Name
  acl    = "public-read"
}


#Saving name of the bucket to local system
resource "null_resource" "null2" {
  depends_on = [
      aws_s3_bucket.my_bucket,
]
  provisioner "local-exec" {
    command = "echo ${aws_s3_bucket.my_bucket.bucket} > bucket_name.txt"
  } 
}


# Cloning git repository to local system
resource "null_resource" "null" {
  provisioner "local-exec" {
// Provide github repo link here after gitclone to provide your webserver code.
   command = "git clone https://github.com/NageshwarPatil/Terraform.git  C:/Users/Nmp/Desktop/Terra/Mytest"
  } 
}


# Upload image file on S3 storage from github repository at local system
resource "aws_s3_bucket_object" "object1" {
  depends_on =[
      null_resource.null,
      aws_s3_bucket.my_bucket
]
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "bucket_image.jpg"
// Provide path here according To your system's file system
  source = "C:/Users/Nmp/Desktop/Terra/Mytest/Terraform/IMG_20200522_193447.jpg"
  acl    = "public-read"
} 



# Cloudfront Distribution Creation
resource "aws_cloudfront_distribution" "s3_distribution" { 
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.my_bucket.bucket
  }
  enabled = true
    default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.my_bucket.bucket
  forwarded_values {
      query_string = false
        cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
output "cloudfront"{
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}




