module SelfSignedCertificate
	# From webrick source code
	# https://github.com/ruby/webrick/blob/master/lib/webrick/ssl.rb
	def create_self_signed_cert(bits, cn, comment)				
	      rsa = OpenSSL::PKey::RSA.new(bits)
	      cert = OpenSSL::X509::Certificate.new
	      cert.version = 2
	      cert.serial = 1
	      name = (cn.kind_of? String) ? OpenSSL::X509::Name.parse(cn)
	                                  : OpenSSL::X509::Name.new(cn)
	      cert.subject = name
	      cert.issuer = name
	      cert.not_before = Time.now
	      cert.not_after = Time.now + (365*24*60*60)
	      cert.public_key = rsa.public_key
	
	      ef = OpenSSL::X509::ExtensionFactory.new(nil,cert)
	      ef.issuer_certificate = cert
	      cert.extensions = [
	        ef.create_extension("basicConstraints","CA:FALSE"),
	        ef.create_extension("keyUsage", "keyEncipherment, digitalSignature, keyAgreement, dataEncipherment"),
	        ef.create_extension("subjectKeyIdentifier", "hash"),
	        ef.create_extension("extendedKeyUsage", "serverAuth"),
	        ef.create_extension("nsComment", comment),
	      ]
	      aki = ef.create_extension("authorityKeyIdentifier",
	                                "keyid:always,issuer:always")
	      cert.add_extension(aki)
	      cert.sign(rsa, "SHA256")

	      # saving
				File.write(File.join(File.dirname(__FILE__),"../certificate/certificate.crt"), cert)
				File.write(File.join(File.dirname(__FILE__),"../certificate/private.key"), rsa)
	  end

	  def exists?
			return true if File.exist?(File.join(File.dirname(__FILE__),"../certificate/certificate.crt")) && 
										 File.exist?(File.join(File.dirname(__FILE__),"../certificate/private.key"))
			return false
	  end
end
